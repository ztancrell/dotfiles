# Linux Dotfiles

Bare Git repository tracking selected configuration files from `$HOME`.

## How It Works

- **Git directory:** `~/.dotfiles` (bare repo)
- **Work tree:** `$HOME` (your actual config files stay in place)
- **Command:** `config` — a shell function defined in `~/.zshrc`

```zsh
function config() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}
```

Only files you explicitly `config add` are tracked. Untracked home files are hidden from `config status`.

## Daily Workflow

```bash
# Check what's changed
config status

# Track a new config file or directory
config add ~/.config/some-app

# Commit changes
config commit -m "Update fastfetch config"

# View history
config log --oneline

# Push to remote (after setting one up)
config push
```

## Adding a Remote

```bash
# Create a private repo on GitHub/GitLab, then:
config remote add origin git@github.com:YOUR_USER/linux-dotfiles.git
config push -u origin main
```

## Restore on a New Machine

```bash
# 1. Clone the bare repo
git clone --bare git@github.com:YOUR_USER/linux-dotfiles.git ~/.dotfiles

# 2. Add the config function to ~/.zshrc (or run directly):
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# 3. Checkout tracked files (only adds/updates tracked paths)
config checkout

# 4. Reload shell
source ~/.zshrc
```

If a file already exists and differs, back it up first:

```bash
mv ~/.zshrc ~/.zshrc.bak
config checkout -- .zshrc
```

## Safety

Sensitive paths are listed in `~/.dotfiles/info/exclude` (SSH keys, browser profiles, credentials, caches). Always review `config status` before committing.

To see all untracked files (normally hidden):

```bash
config status -u
```

## Currently Tracked

Configs are matched to installed packages (`pacman -Qqe`). Browser profiles, caches, and credentials are excluded.

### Shell & Desktop
| Path | Package |
|------|---------|
| `~/.zshrc` | zsh |
| `~/.p10k.zsh` | cachyos-zsh-config |
| `~/.dmrc` | ly (default session) |
| `~/.fehbg` | feh (wallpaper script) |
| `~/redshift-cli.sh` | redshift (tray launcher) |
| `~/.config/openbox/` | openbox |
| `~/.config/tint2/` | tint2 |
| `~/.config/lxpanel/` | lxpanel |
| `~/.config/obmenu-generator/` | obmenu-generator |
| `~/.config/autostart/` | xdg-autostart |
| `~/.config/systemd/user/` | user services (psd, shelly, pulse-mic-gain) |

### GTK & Appearance
| Path | Package |
|------|---------|
| `~/.config/gtk-2.0/` | gtk |
| `~/.config/gtk-3.0/settings.ini` | gtk |
| `~/.config/gtk-4.0/gtk.css` | gtk |
| `~/.config/gtkrc` | gtk |
| `~/.config/gtkrc-2.0` | gtk |
| `~/.config/mimeapps.list` | xdg |
| `~/.config/user-dirs.dirs` | xdg-user-dirs |
| `~/.config/user-dirs.locale` | xdg-user-dirs |

### Apps
| Path | Package |
|------|---------|
| `~/.config/fastfetch/` | fastfetch |
| `~/.config/flameshot/` | flameshot |
| `~/.config/htop/htoprc` | htop |
| `~/.config/micro/` | micro (settings + colorschemes) |
| `~/.config/mousepad/` | mousepad |
| `~/.config/xed/` | xed |
| `~/.config/Thunar/` | thunar |
| `~/.config/xarchiver/` | xarchiver |
| `~/.config/audacious/` | audacious |
| `~/.config/bleachbit/` | bleachbit-git |
| `~/.config/vlc/` | vlc-plugins-all |
| `~/.config/pavucontrol.ini` | pavucontrol |
| `~/.config/psd/` | profile-sync-daemon |
| `~/.config/shelly/` | shelly |
| `~/.config/lact/` | lact-git |
| `~/.config/cachyos/` | cachyos-* |
| `~/.config/Cursor/User/settings.json` | cursor-nightly-bin |
| `~/.config/obs-studio/basic/` | obs-studio-git (scenes + profiles) |
| `~/.config/obs-studio/global.ini` | obs-studio-git |
| `~/.config/obs-studio/user.ini` | obs-studio-git |
| `~/.config/heroic/config.json` | heroic-games-launcher-bin |
| `~/.config/qBittorrent/qBittorrent.conf` | qbittorrent |

### Gaming
| Path | Package |
|------|---------|
| `~/.config/vkbasalt/` | vkbasalt |
| `~/.config/MangoHud/MangoHud.conf` | gamemode |

### System configs (`~/etc/`)

System-wide configs live in `/etc/` on the machine. Copies are tracked under `~/etc/` and deployed with:

```bash
sudo ~/etc/install.sh              # deploy all
sudo ~/etc/install.sh ly/config.ini  # deploy one file
```

| Mirror path | Package | Deploys to |
|-------------|---------|------------|
| `~/etc/ly/config.ini` | ly | `/etc/ly/config.ini` |
| `~/etc/X11/xorg.conf.d/` | xlibre-xserver | `/etc/X11/xorg.conf.d/` |
| `~/etc/modprobe.d/99-amdgpu-overdrive.conf` | amd-ucode | `/etc/modprobe.d/` |
| `~/etc/NetworkManager/NetworkManager.conf` | networkmanager | `/etc/NetworkManager/` |
| `~/etc/mkinitcpio.conf` | mkinitcpio | `/etc/mkinitcpio.conf` |
| `~/etc/mkinitcpio.conf.d/` | limine-mkinitcpio-hook | `/etc/mkinitcpio.conf.d/` |
| `~/etc/limine-snapper-sync.conf` | limine-snapper-sync | `/etc/limine-snapper-sync.conf` |
| `~/etc/limine-entry-tool.conf` | limine | `/etc/limine-entry-tool.conf` |
| `~/etc/snapper/configs/root` | snapper | `/etc/snapper/configs/root` |
| `~/etc/ufw/` | ufw | `/etc/ufw/` |
| `~/etc/dunst/dunstrc` | dunst | `/etc/dunst/dunstrc` |
| `~/etc/sysctl.d/50-cursor.conf` | (local) | `/etc/sysctl.d/` |

**xlibre note:** There is no `~/.config/xlibre`. GPU/monitor/input tweaks go in `/etc/X11/xorg.conf.d/*.conf` — see `~/etc/X11/xorg.conf.d/README.md`.

Add more configs over time with `config add <path>`.
