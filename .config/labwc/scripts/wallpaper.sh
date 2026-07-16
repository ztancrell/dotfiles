#!/bin/bash
# Random wallpaper selector for labwc/swaybg
# Usage: wallpaper.sh [--set|--next|--current]
#   --set     Set a random wallpaper (default, used at login)
#   --next    Kill current swaybg and set a new random wallpaper
#   --current Print the current wallpaper path

WALLPAPER_DIR="$HOME/.wallpapers"
CURRENT_FILE="$HOME/.cache/current-wallpaper"

# Find all image files recursively
get_random_wallpaper() {
    find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) 2>/dev/null | shuf -n 1
}

set_wallpaper() {
    local wallpaper="$1"
    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        # Fallback to solid color
        pkill -x swaybg 2>/dev/null
        swaybg -c "#0d0d0d" &
        return 1
    fi
    
    # Save current wallpaper path
    mkdir -p "$(dirname "$CURRENT_FILE")"
    echo "$wallpaper" > "$CURRENT_FILE"
    
    # Kill existing swaybg and start new one
    pkill -x swaybg 2>/dev/null
    sleep 0.1
    swaybg -i "$wallpaper" -m fill &
    
    echo "Wallpaper set: $(basename "$wallpaper")"
}

case "${1:---set}" in
    --set)
        wallpaper=$(get_random_wallpaper)
        set_wallpaper "$wallpaper"
        ;;
    --next)
        wallpaper=$(get_random_wallpaper)
        set_wallpaper "$wallpaper"
        ;;
    --current)
        if [ -f "$CURRENT_FILE" ]; then
            cat "$CURRENT_FILE"
        else
            echo "No wallpaper set"
        fi
        ;;
    *)
        echo "Usage: wallpaper.sh [--set|--next|--current]"
        exit 1
        ;;
esac
