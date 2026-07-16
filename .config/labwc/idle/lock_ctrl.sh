#!/bin/bash

# Lock screen controller for Labwc (uses swaylock or loginctl)
# Prevents double locking when device goes to sleep

if pgrep -x "swaylock" > /dev/null; then
    echo "Session Already Locked" 
    exit 0       
else
    echo "Locking Session"
    # Use swaylock if available, otherwise fall back to loginctl
    if command -v swaylock &>/dev/null; then
        swaylock -f
    else
        loginctl lock-session
    fi
fi