#!/bin/sh
printf '%s\n' '<?xml version="1.0"?><openbox_pipe_menu>'

# header item to launch GNOME Software (optional)
# printf '%s\n' "<item label=\"Flatpak Software\"><action name=\"Execute\"><command=gnome-software></command></action></item>"

flatpak list --app --columns=application,ref | while IFS=$'\t' read -r name ref; do
  # escape XML entities in name
  esc_name=$(printf '%s' "$name" | sed -e 's/&/&amp;/g' -e "s/</\&lt;/g" -e "s/>/\&gt;/g" -e "s/\"/\&quot;/g")
  printf '<item label="%s"><action name="Execute"><command>flatpak run %s</command></action></item>\n' "$esc_name" "$ref"
done

printf '%s\n' '</openbox_pipe_menu>'
