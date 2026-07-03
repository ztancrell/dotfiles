#!/bin/bash

SOUND_DIR="$HOME/.config/openbox/sound"
AUDIO_ADDED="$SOUND_DIR/device-added.oga"
AUDIO_REMOVED="$SOUND_DIR/device-removed.oga"
COOLDOWN_FILE="/tmp/device-monitor-cooldown"
COOLDOWN_SECONDS=3

play_sound() {
    local sound_file="$1"

    if [ -f "$COOLDOWN_FILE" ]; then
        last_play=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
        now=$(date +%s)
        if [ $((now - last_play)) -lt $COOLDOWN_SECONDS ]; then
            return
        fi
    fi

    date +%s > "$COOLDOWN_FILE"
    paplay "$sound_file" &
}

udevadm monitor --udev --subsystem-match=usb --subsystem-match=block | while read -r line; do
    if [[ "$line" == *"["* ]]; then
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
