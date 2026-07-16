#!/bin/sh
# Verify Labwc NIGHT-RED theme is applied correctly
THEME_FILE="$HOME/.config/labwc/themerc"
EXPECTED_COLOR="#b22222"

if [ -f "$THEME_FILE" ]; then
    CURRENT_COLOR=$(grep "window.active.title.bg.color" "$THEME_FILE" | cut -d' ' -f3)
    if [ "$CURRENT_COLOR" != "$EXPECTED_COLOR" ]; then
        echo "Fixing theme color..."
        sed -i "s/window.active.title.bg.color.*/window.active.title.bg.color: $EXPECTED_COLOR/" "$THEME_FILE"
        labwc --reconfigure
    fi
fi
