# dotfiles

My Zsh, Openbox, tint2, desktop and app configs on CachyOS. This is a bare Git
repository at `~/.dotfiles`; tracked files live in `$HOME`. Wallpapers are included.

## Manage configs

The following helper is defined in `~/.zshrc`:

```zsh
function config() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}
```

Check `config status` before changing the repo. New files require an explicit,
reviewed `config add path`. Never bulk-add your home directory.

## Hourly backup

`dotfiles-tools/backup.py` saves changes to already-tracked files, including deletions,
then pushes to `origin/main`. It creates a commit only when files changed and retries
unpushed snapshots on the next run. It never pulls, force-pushes, or rewrites history.
If GitHub has diverged, it stops for manual resolution. Manual staged changes and
in-progress merges/rebases also stop the job without changing your index.

Requirements: Python 3, Git, systemd user services, notify-send, and working
noninteractive GitHub authentication. The repository uses HTTPS with the existing
Git credential helper. Credentials belong outside this repo.

Enable the timer after installation or restore:

```sh
systemctl --user daemon-reload
systemctl --user enable --now dotfiles-backup.timer
systemctl --user start dotfiles-backup.service
```

It runs hourly, with up to five minutes of jitter. A missed scheduled run is caught
when the timer becomes active again. User services normally run while logged in.
Offline runs still create local snapshots; pushing resumes on a later successful run.
Failures appear in the journal and trigger a desktop notification where available.

```sh
systemctl --user list-timers dotfiles-backup.timer
journalctl --user -u dotfiles-backup.service -n 40 --no-pager
python3 ~/dotfiles-tools/backup.py --check
```

`--check` reviews tracked working files without committing or contacting GitHub.
Run the offline integration tests with `python3 ~/dotfiles-tools/test_backup.py`.
Pause automation with `systemctl --user stop dotfiles-backup.timer`.

The scanner rejects known private paths, common credential formats, sensitive
settings, and history sections. Every outgoing commit is checked, including earlier
manual commits. It logs locations and reasons, never matching values. These are
heuristic checks, not a guarantee that arbitrary personal information will be found.
Review newly tracked configs yourself. Do not bypass a privacy failure by pushing
manually; inspect and remove sensitive data from all unpublished commits first.

## Restore on a new machine

Install Git and the applications whose configs you want to use, then:

```zsh
git clone --bare https://github.com/ztancrell/dotfiles.git "$HOME/.dotfiles"
function config() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}
config config status.showUntrackedFiles no
config checkout
```

If checkout reports existing files, move those files to a backup location and retry.
Do not force checkout over settings you still need. Open a new Zsh session afterward.
Configure Git author identity and GitHub authentication before enabling the timer.
Cloning restores tracked files only: it does not install apps or restore private app
state, documents, passwords, or other excluded files. Some configs contain paths
under `/home/zpt`; adjust those if your home directory differs.

## Recover an older config

Stop the timer and let any active backup finish before restoring:

```sh
systemctl --user stop dotfiles-backup.timer
systemctl --user is-active dotfiles-backup.service
```

When the service is inactive, find the desired commit and inspect its version first:

```zsh
config log --oneline -- .zshrc
config show COMMIT:.zshrc > /tmp/zshrc-recovered
zsh -n /tmp/zshrc-recovered
```

Replace `COMMIT` with an actual hash. Back up your current file, then restore it:

```zsh
cp -p ~/.zshrc ~/.zshrc.before-restore
config restore --source=COMMIT --worktree -- .zshrc
systemctl --user start dotfiles-backup.timer
```

Use the same commands with another tracked path as needed. The next hourly backup
records the restored settings as a new commit, preserving the intervening history.
Try this recovery flow into a temporary file periodically.

## System configs

`~/etc/` contains manually maintained copies of selected system configs. The hourly
job backs up those copies; it does not refresh them from `/etc`. Review before deploying:

```sh
sudo ~/etc/install.sh ly/config.ini
```

## Privacy and cleanup

Ignore rules are tracked in `~/.gitignore`, with extra local rules possible in
`~/.dotfiles/info/exclude`. Ignore rules do not exclude already-tracked files.

OBS, qBittorrent, Astro, BleachBit, Heroic account config, GTK file-chooser state,
and VLC interface history remain local-only. Older published commits may still
contain previously tracked app state; exclusions do not erase Git history.

Unused Bash startup files and Conky, Nitrogen, PCManFM, Sakura, and Mousepad configs
are excluded. Their local copies were preserved. Bash helper scripts remain because
their shebang selects Bash independently of the interactive Zsh shell. Openbox's
file-manager, terminal, and editor shortcuts use Thunar, Alacritty, and Xed.
