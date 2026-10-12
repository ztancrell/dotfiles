"""Offline integration tests using disposable bare repositories."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('backup', Path(__file__).with_name('backup.py'))
backup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backup)


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.home = root / 'home'
        self.home.mkdir()
        self.remote = root / 'remote.git'
        subprocess.run(['git', 'init', '--bare', '-q', str(self.remote)], check=True)
        subprocess.run(['git', 'init', '--bare', '-q', '-b', 'main', str(self.home / '.dotfiles')], check=True)
        self.b = backup.Backup(self.home)
        self.b.git('config', 'user.name', 'Backup Test')
        self.b.git('config', 'user.email', 'test@example.invalid')
        self.b.git('config', 'commit.gpgsign', 'false')
        self.file = self.home / '.zshrc'
        self.file.write_text('export EDITOR=xed\n')
        self.b.git('add', '.zshrc')
        self.b.git('commit', '-m', 'Initial')
        self.b.git('remote', 'add', 'origin', str(self.remote))
        self.b.git('push', 'origin', 'main')
        self.start = self.b.git('rev-parse', 'HEAD')

    def test_snapshot_push_and_noop(self):
        self.file.write_text('export EDITOR=vim\n')
        (self.home / 'untracked-private.txt').write_text('local only')
        self.b.run()
        tip = self.b.git('rev-parse', 'HEAD')
        self.assertNotEqual(self.start, tip)
        self.assertEqual(tip, self.b.git('rev-parse', 'origin/main'))
        self.assertEqual(b'', self.b.git('diff', '--cached', '--name-only'))
        self.assertEqual(b'', self.b.git('diff', '--name-only'))
        self.assertNotIn(b'untracked-private', self.b.git('ls-tree', '-r', '--name-only', 'HEAD'))
        self.b.run()
        self.assertEqual(tip, self.b.git('rev-parse', 'HEAD'))

    def test_secret_rejected_without_touching_index(self):
        index = (self.b.repo / 'index').read_bytes()
        self.file.write_text('export API_' + 'KEY="' + 'private-test-value' + '"\n')
        with self.assertRaisesRegex(RuntimeError, 'Privacy check'):
            self.b.run()
        self.assertEqual(self.start, self.b.git('rev-parse', 'HEAD'))
        self.assertEqual(index, (self.b.repo / 'index').read_bytes())
        self.assertFalse((self.b.repo / 'index.lock').exists())

    def test_manual_staging_preserved(self):
        self.file.write_text('export EDITOR=vim\n')
        self.b.git('add', '.zshrc')
        index = (self.b.repo / 'index').read_bytes()
        with self.assertRaisesRegex(RuntimeError, 'Manual staged'):
            self.b.run()
        self.assertEqual(index, (self.b.repo / 'index').read_bytes())

    def test_outgoing_old_secret_commit_blocks_push(self):
        self.file.write_text('export API_' + 'KEY="' + 'private-test-value' + '"\n')
        self.b.git('add', '.zshrc')
        self.b.git('commit', '-m', 'Unsafe manual commit')
        self.file.write_text('export EDITOR=vim\n')
        self.b.git('add', '.zshrc')
        self.b.git('commit', '-m', 'Remove private value')
        with self.assertRaisesRegex(RuntimeError, 'Privacy check'):
            self.b.run()
        self.assertEqual(self.start, self.b.git('rev-parse', 'origin/main'))

    def test_offline_keeps_local_snapshot(self):
        self.file.write_text('export EDITOR=vim\n')
        self.b.git('remote', 'set-url', 'origin', str(self.home / 'missing.git'))
        with self.assertRaisesRegex(RuntimeError, 'fetch failed'):
            self.b.run()
        self.assertNotEqual(self.start, self.b.git('rev-parse', 'HEAD'))
        self.assertEqual(b'', self.b.git('diff', '--cached', '--name-only'))

    def test_check_does_not_commit(self):
        self.file.write_text('export EDITOR=vim\n')
        self.b.run(check_only=True)
        self.assertEqual(self.start, self.b.git('rev-parse', 'HEAD'))

    def test_existing_index_lock_is_preserved(self):
        lock = self.b.repo / 'index.lock'
        lock.write_text('another git process')
        with self.assertRaises(FileExistsError):
            self.b.run()
        self.assertEqual('another git process', lock.read_text())

    def test_private_path_rejected(self):
        private = self.home / '.config/astro/config.json'
        private.parent.mkdir(parents=True)
        private.write_text('{}')
        self.b.git('add', '.config/astro/config.json')
        self.b.git('commit', '-m', 'Accidentally track private state')
        with self.assertRaisesRegex(RuntimeError, 'private path'):
            self.b.run()
        self.assertEqual(self.start, self.b.git('rev-parse', 'origin/main'))

    def test_remote_divergence_does_not_overwrite(self):
        tree = self.b.git('rev-parse', 'HEAD^{tree}').decode().strip()
        remote_tip = self.b.git('commit-tree', tree, '-p', 'HEAD', '-m', 'Remote change').decode().strip()
        self.b.git('push', 'origin', remote_tip + ':refs/heads/main')
        self.file.write_text('export EDITOR=vim\n')
        with self.assertRaisesRegex(RuntimeError, 'merge-base failed'):
            self.b.run()
        self.assertEqual(remote_tip, self.b.git('rev-parse', 'origin/main').decode().strip())

    def test_deleted_config_can_be_recovered(self):
        self.file.unlink()
        self.b.run()
        restored = self.b.git('show', self.start.decode().strip() + ':.zshrc')
        self.assertEqual(b'export EDITOR=xed\n', restored)

    def test_json_and_history_findings_do_not_leak_values(self):
        value = 'private-test-value'
        findings = backup.inspect_text('settings.json', '{"access_' + 'token":"' + value + '"}')
        self.assertTrue(findings)
        self.assertNotIn(value, '\n'.join(findings))
        self.assertTrue(backup.inspect_text('settings.ini', '[RecentMRL]\nlist=example\n'))


if __name__ == '__main__':
    unittest.main()
