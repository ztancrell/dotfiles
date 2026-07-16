#!/bin/bash

SOUND_DIR="$HOME/.config/labwc/sound"
AUDIO_ADDED="$SOUND_DIR/device-added.oga"
AUDIO_REMOVED="$SOUND_DIR/device-removed.oga"
COOLDOWN_FILE="/tmp/device-monitor-cooldown"
COOLDOWN_SECONDS=3

echo "Starting hardware monitor... (Press Ctrl+C to stop)"

play_sound() {
    local sound_file="$1"
    
    # Check cooldown to prevent sound spam (e.g., during sleep/wake)
    if [ -f "$COOLDOWN_FILE" ]; then
        last_play=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
        now=$(date +%s)
        if [ $((now - last_play)) -lt $COOLDOWN_SECONDS ]; then
            return
        fi
    fi
    
    # Update cooldown timestamp
    date +%s > "$COOLDOWN_FILE"
    
    # Play sound
    paplay "$sound_file" &
}

udevadm monitor --udev --subsystem-match=usb --subsystem-match=block | while read -r line; do
    # Only process actual device events, not subsystem spam
    # Actual events look like: UDEV  [350.433478] add|remove   /devices/...
    if [[ "$line" == *"["* ]]; then
        # Skip internal USB hubs and controllers (they trigger on sleep/wake)
        if [[ "$line" == *"/usb"[0-9]" "* ]] || [[ "$line" == *"/usb"[0-9]"/"*"/usb"[0-9]"-"[0-9]" "* && "$line" != *"-"[0-9]"."* ]]; then
            continue
        fi
        
        if [[ "$line" == *" add "* ]]; then
            play_sound "$AUDIO_ADDED"
        elif [[ "$line" == *" remove "* ]]; then
            play_sound "$AUDIO_REMOVED"
        fi
    fi
done