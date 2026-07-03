# xlibre / Xorg configuration

Package: `xlibre-xserver`

xlibre does **not** store settings in `~/.config`. Configuration is system-wide:

| Location | Purpose |
|----------|---------|
| `/etc/X11/xorg.conf.d/*.conf` | **Your custom snippets** (create these; highest priority for local overrides) |
| `/usr/share/X11/xorg.conf.d/*.conf` | Package defaults (do not edit; managed by pacman) |
| `/etc/X11/xinit/xinitrc` | Used when starting X via `startx` (you use **ly** instead) |

## Adding a custom snippet

1. Create a file here in the repo mirror, e.g. `etc/X11/xorg.conf.d/20-amdgpu.conf`
2. Deploy: `sudo cp ~/etc/X11/xorg.conf.d/20-amdgpu.conf /etc/X11/xorg.conf.d/`
3. Restart your X session

Example monitor/GPU snippet:

```
Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    Option "TearFree" "true"
EndSection
```

## Your setup

- Display manager: **ly** (`/etc/ly/config.ini`)
- Session: **openbox** (`~/.dmrc`)
- GPU modprobe option: `etc/modprobe.d/99-amdgpu-overdrive.conf`

No xlibre snippets exist yet on this machine — add `.conf` files here when needed.
