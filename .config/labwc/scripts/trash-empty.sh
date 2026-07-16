#!/bin/bash
# Empty trash with sound feedback

TRASH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"

if [ -d "$TRASH_DIR/files" ] && [ "$(ls -A "$TRASH_DIR/files" 2>/dev/null)" ]; then
    rm -rf "$TRASH_DIR/files/"* "$TRASH_DIR/info/"* 2>/dev/null
    paplay ~/.config/labwc/sound/trash-empty.oga &
    notify-send "Trash" "Trash emptied successfully" -i user-trash
else
    notify-send "Trash" "Trash is already empty" -i user-trash
fi
