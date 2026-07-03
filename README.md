# dotfiles

A simple `$HOME` for my dotfiles. :3

Bare git repo at `~/.dotfiles`. Files stay where they are — I only track what I `config add`.

Stack is mostly openbox + ly + tint2 on CachyOS. Wallpapers included because feh cares.

## `config`

Defined in `~/.zshrc`:

```zsh
function config() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}
```

`config status` hides untracked home junk. `config status -u` if you want the full mess.

## day to day

```bash
config status
config add ~/.config/some-app
config commit -m "whatever"
config push
```

## new machine

```bash
git clone --bare git@github.com:ztancrell/dotfiles.git ~/.dotfiles

# stick this in ~/.zshrc
function config() {
  git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

config checkout
source ~/.zshrc
```

File already there and different? back it up first:

```bash
mv ~/.zshrc ~/.zshrc.bak
config checkout -- .zshrc
```

System stuff under `~/etc/` is separate — deploy with sudo:

```bash
sudo ~/etc/install.sh
sudo ~/etc/install.sh ly/config.ini   # one file
```

## what's in here

**shell** — `.zshrc`, `.p10k.zsh`, `.dmrc`

**desktop** — openbox (with ui sounds), tint2, lxpanel, obmenu-generator, autostart, feh wallpapers, `~/redshift-cli.sh`

**gtk** — gtk-2/3/4, gtkrc, mimeapps, user-dirs

**apps** — fastfetch, flameshot, htop, micro, thunar, xed, mousepad, vlc, audacious, bleachbit, pavucontrol, psd, shelly, lact, cachyos, cursor settings, obs scenes, heroic config, qbittorrent

**gaming** — vkbasalt, mangohud

**wallpapers** — `~/.wallpapers/` (artstation, berserk, sst, templars)

**system mirror** — `~/etc/` copies of ly, mkinitcpio, limine, snapper, ufw, networkmanager, dunst, amdgpu modprobe, sysctl. xlibre snippets go in `~/etc/X11/xorg.conf.d/` (see readme there).

## not tracked on purpose

ssh keys, browser profiles, bitwarden, heroic/steam caches, that kind of thing. list is in `~/.dotfiles/info/exclude`.

glance at `config status` before you commit anyway.
