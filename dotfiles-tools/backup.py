#!/usr/bin/env python3
"""Snapshot tracked dotfiles and push only privacy-checked outgoing history."""
import argparse
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


PRIVATE_PATHS = (
    '.ssh/', '.gnupg/', '.aws/', '.azure/', '.codex/', '.claude/',
    '.config/gh/', '.config/gcloud/', '.config/astro/', '.config/bleachbit/',
    '.config/obs-studio/', '.config/qBittorrent/', '.config/Bitwarden/',
    '.config/chromium/', '.config/google-chrome/', '.config/BraveSoftware/',
    '.config/mozilla/', '.config/firefox/', '.config/vivaldi/',
    '.config/Cursor/User/globalStorage/', '.config/Cursor/User/workspaceStorage/',
    '.config/Cursor/User/History/', '.local/', '.cache/',
)
PRIVATE_FILES = {
    '.netrc', '.npmrc', '.git-credentials', '.bash_history', '.zsh_history',
    '.config/heroic/config.json', '.config/gtk-2.0/gtkfilechooser.ini',
    '.config/vlc/vlc-qt-interface.conf',
}
SENSITIVE_KEY = re.compile(
    r'password|passwd|secret|token|api.?key|authorization|cookie|credential|'
    r'email|username|anonymous.?id|install.?guid|hashsalt|lastfolder|'
    r'(?:downloadpath|savepath|playback|search)history|latitude|longitude', re.I)
SECRET = re.compile(
    r'-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----|'
    r'\bgh[pousr]_[A-Za-z0-9]{20,}|\bgithub_pat_[A-Za-z0-9_]{30,}|'
    r'\bsk-[A-Za-z0-9_-]{20,}|\bAKIA[A-Z0-9]{16}|'
    r'\beyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+|'
    r'https?://[^\s/:]+:[^\s/@]+@')
ASSIGNMENT = re.compile(r'''^\s*(?:export\s+)?["']?([\w.\\-]+)["']?\s*[:=]\s*(.*?)\s*,?\s*$''')


def meaningful(value):
    if value is None or isinstance(value, bool):
        return False
    if isinstance(value, (dict, list)):
        return bool(value)
    return str(value).strip().strip('\"\'').lower() not in {
        '', 'false', 'true', 'none', 'null', '0', '@invalid()', '@bytearray()',
    }


def inspect_text(path, text):
    """Return locations/reasons only; never include matching private values."""
    errors = []
    for number, line in enumerate(text.splitlines(), 1):
        if SECRET.search(line):
            errors.append(f'{path}:{number}: possible credential')
        if line.lstrip().startswith(('#', ';', '//')):
            continue
        match = ASSIGNMENT.match(line)
        if (match and match[1] != 'show_password_key'
                and SENSITIVE_KEY.search(match[1]) and meaningful(match[2])
                and not match[2].strip('\"\'').startswith('$')
                and (not path.endswith('.py') or match[2].startswith(('\"', "'")))):
            errors.append(f'{path}:{number}: private setting')
        if re.match(r'\s*\[(?:Recent|History)', line, re.I):
            errors.append(f'{path}:{number}: history section')
    if path.endswith('.json'):
        try:
            data = json.loads(text)
        except ValueError:
            errors.append(f'{path}: invalid JSON; review manually')
        else:
            def walk(obj):
                if isinstance(obj, dict):
                    for key, value in obj.items():
                        if SENSITIVE_KEY.search(key) and meaningful(value):
                            errors.append(f'{path}: private JSON setting')
                        walk(value)
                elif isinstance(obj, list):
                    for value in obj:
                        walk(value)
            walk(data)
    return errors


class Backup:
    def __init__(self, home):
        self.home = home
        self.repo = home / '.dotfiles'
        self.env = os.environ.copy()
        self.env['GIT_TERMINAL_PROMPT'] = '0'
        self.env['GCM_INTERACTIVE'] = 'Never'
        self.checked = set()

    def git(self, *args, env=None, data=None):
        result = subprocess.run(
            ['git', f'--git-dir={self.repo}', f'--work-tree={self.home}', *args],
            cwd=self.home, env=env or self.env, input=data, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, timeout=180)
        if result.returncode:
            # Git diagnostics may contain URLs or credentials. Keep logs value-free.
            raise RuntimeError(f'Git {args[0]} failed (exit {result.returncode}); inspect manually')
        return result.stdout

    def scan(self, tree):
        errors = []
        for entry in self.git('ls-tree', '-rlz', tree).split(b'\0'):
            if not entry:
                continue
            meta, raw_path = entry.split(b'\t', 1)
            mode, kind, oid, size = meta.split()
            path = os.fsdecode(raw_path)
            name = Path(path).name
            if (path.startswith(PRIVATE_PATHS) or path in PRIVATE_FILES
                    or name == '.env' or name.startswith('.env.')
                    or name.endswith(('.pem', '.key', '.p12'))):
                errors.append(f'{path}: private path must not be tracked')
                continue
            identity = (path, oid)
            if identity in self.checked:
                continue
            if kind != b'blob':
                errors.append(f'{path}: unsupported tracked object')
                continue
            # Existing wallpapers and desktop sounds are expected binary assets.
            if path.startswith(('.wallpapers/', '.config/openbox/sound/')) and Path(path).suffix in {'.jpg', '.png', '.oga'}:
                self.checked.add(identity)
                continue
            if int(size) > 2 * 1024 * 1024:
                errors.append(f'{path}: too large for automatic review')
                continue
            data = self.git('cat-file', 'blob', oid.decode())
            try:
                text = data.decode('utf-8-sig')
            except UnicodeError:
                errors.append(f'{path}: unexpected binary file')
                continue
            errors.extend(inspect_text(path, text))
            self.checked.add(identity)
        if errors:
            raise RuntimeError('Privacy check blocked backup:\n' + '\n'.join(sorted(set(errors))))

    def snapshot(self, check_only=False):
        lock = self.repo / 'index.lock'
        fd = os.open(lock, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        owns_lock = True
        try:
            head = self.git('rev-parse', 'HEAD').decode().strip()
            if self.git('diff', '--cached', '--name-only'):
                raise RuntimeError('Manual staged changes exist; commit or unstage them first')
            for marker in ('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply'):
                if (self.repo / marker).exists():
                    raise RuntimeError('Git operation in progress; finish it first')
            with tempfile.TemporaryDirectory(prefix='backup-index-', dir=self.repo) as tmp:
                index = Path(tmp) / 'index'
                env = dict(self.env, GIT_INDEX_FILE=str(index))
                self.git('read-tree', head, env=env)
                self.git('add', '-u', '--', '.', env=env)
                tree = self.git('write-tree', env=env).decode().strip()
                self.scan(tree)
                if check_only:
                    print('Tracked working snapshot passed privacy checks; nothing committed or pushed.')
                    return
                old_tree = self.git('rev-parse', head + '^{tree}').decode().strip()
                if tree != old_tree:
                    message = 'Automatic config backup ' + datetime.datetime.now().astimezone().isoformat(timespec='seconds')
                    commit = self.git('commit-tree', tree, '-p', head, '-m', message).decode().strip()
                    # Holding the real index lock protects manual staging throughout.
                    with os.fdopen(os.dup(fd), 'wb') as output:
                        output.write(index.read_bytes())
                        output.flush()
                        os.fsync(output.fileno())
                    self.git('update-ref', '-m', message, 'HEAD', commit, head)
                    os.replace(lock, self.repo / 'index')
                    owns_lock = False
                    print('Saved local config snapshot ' + commit[:12])
                else:
                    print('No config changes to save.')
        finally:
            os.close(fd)
            if owns_lock:
                lock.unlink(missing_ok=True)

    def run(self, check_only=False):
        branch = self.git('symbolic-ref', '--short', 'HEAD').decode().strip()
        if branch != 'main':
            raise RuntimeError('Automatic backup only runs on main')
        self.snapshot(check_only)
        if check_only:
            return
        tip = self.git('rev-parse', 'HEAD').decode().strip()
        self.git('fetch', 'origin', 'refs/heads/main:refs/remotes/origin/main')
        self.git('merge-base', '--is-ancestor', 'origin/main', tip)
        outgoing = self.git('rev-list', 'origin/main..' + tip).decode().splitlines()
        # Scan each outgoing snapshot, including earlier manual/offline commits.
        for commit in outgoing:
            self.scan(commit)
        if outgoing:
            self.git('push', 'origin', tip + ':refs/heads/main')
            print(f'Pushed {len(outgoing)} checked commit(s).')
        else:
            print('GitHub is already up to date.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='review tracked working files without committing or networking')
    args = parser.parse_args()
    home = Path.home()
    state = home / '.local/state/dotfiles-backup'
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / 'lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('Another backup is running.')
            return 0
        try:
            os.chdir(home)
            Backup(home).run(args.check)
        except Exception as error:
            print(str(error), file=sys.stderr)
            return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
