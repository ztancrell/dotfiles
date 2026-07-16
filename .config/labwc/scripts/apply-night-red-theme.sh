#!/bin/sh
# Force-apply NIGHT-RED theme (red titlebar, white buttons, dark menu).
# Run this if labwc decorations or right-click menu don't show NIGHT-RED.

CONFIG_LABWC="$HOME/.config/labwc"
THEME_DEST="$HOME/.local/share/themes/NIGHT-RED/openbox-3"

mkdir -p "$THEME_DEST"

# 1. Use the themerc from config (installed from repo) in the theme directory
#    so labwc finds NIGHT-RED with correct colors when loading by theme name
if [ -f "$CONFIG_LABWC/themerc" ]; then
    cp "$CONFIG_LABWC/themerc" "$THEME_DEST/themerc"
fi

# 2. Ensure we have XBM buttons (copy from Vermello if missing)
if [ ! -f "$THEME_DEST/close.xbm" ] && [ -d "$HOME/.local/share/themes/Vermello/openbox-3" ]; then
    cp "$HOME/.local/share/themes/Vermello/openbox-3"/*.xbm "$THEME_DEST/" 2>/dev/null || true
fi

# 3. Keep themerc-override (installed by install.sh) so menu + titlebar stay NIGHT-RED
# Remove rc.xml so theme name is from labwc.xml only
rm -f "$CONFIG_LABWC/rc.xml"

# 4. Reconfigure
labwc --reconfigure 2>/dev/null || true
echo "NIGHT-RED theme applied. If unchanged, log out and back in."
