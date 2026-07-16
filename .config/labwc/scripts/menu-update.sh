#!/bin/bash

# Simple menu update script for Labwc
# Updates the application menu using the Python generator

MENU_GENERATOR="$HOME/.config/labwc/scripts/menu-generator.py"
MENU_FILE="$HOME/.config/labwc/menu.xml"

echo "Updating Labwc application menu..."

# Check if menu generator exists
if [ ! -f "$MENU_GENERATOR" ]; then
    echo "Error: menu-generator.py not found at $MENU_GENERATOR"
    exit 1
fi

# Generate menu without icons (cleaner look)
if python3 "$MENU_GENERATOR" --no-icons -o "$MENU_FILE"; then
    echo "Menu updated successfully"
    
    # Reload labwc configuration
    if command -v labwcctl >/dev/null 2>&1; then
        labwcctl reload
        echo "Labwc reloaded"
    else
        echo "Restart Labwc to see menu changes"
    fi
    
    # Log to systemd journal
    if command -v logger >/dev/null 2>&1; then
        logger -t labwc-menu "Application menu updated successfully"
    fi
else
    echo "Error: Failed to generate menu"
    exit 1
fi
