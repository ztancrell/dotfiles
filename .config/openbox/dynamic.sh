#!/usr/bin/env bash
set -eu

esc(){ printf '%s' "$1" | sed -e 's/&/&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e "s/'/\&apos;/g" -e 's/\"/\&quot;/g'; }

echo '<?xml version="1.0"?>'
echo '<openbox_pipe_menu>'

# ~/bin executables
for f in "$HOME"/bin/*; do
  [ -f "$f" ] || continue
  [ -x "$f" ] || continue
  printf '  <item label="%s">\n' "$(esc "$(basename "$f")")"
  printf '    <action name="Execute">\n      <execute>%s</execute>\n    </action>\n' "$f"
  printf '  </item>\n'
done

# Gather desktop dirs (user first)
desktops=()
desktops+=("$HOME/.local/share/applications")
if [ -n "${XDG_DATA_DIRS:-}" ]; then
  for d in ${XDG_DATA_DIRS//:/ }; do desktops+=("$d/applications"); done
else
  desktops+=("/usr/share/applications")
fi

declare -A seen

for dir in "${desktops[@]}"; do
  [ -d "$dir" ] || continue
  while IFS= read -r f; do
    # avoid duplicates
    if [[ -n "${seen[$f]:-}" ]]; then continue; fi
    seen[$f]=1
    # basic filters
    grep -qi '^NoDisplay=true' "$f" && continue
    grep -qi '^Hidden=true' "$f" && continue
    name=$(grep -m1 '^Name=' "$f" 2>/dev/null | sed 's/^Name=//')
    execline=$(grep -m1 '^Exec=' "$f" 2>/dev/null | sed 's/^Exec=//')
    [ -z "$execline" ] && continue
    token=$(echo "$execline" | awk '{print $1}' | sed 's/%.*//')
    [ -z "$token" ] && continue
    # handle /usr/bin/env wrappers
    if [[ "$token" =~ (^/usr/bin/env$|^/bin/env$) ]]; then
      token=$(echo "$execline" | awk '{print $2}')
    fi
    # check existence
    ok=false
    if [[ "$token" == /* ]]; then
      [ -x "$token" ] && ok=true
    else
      command -v "$token" >/dev/null 2>&1 && ok=true
    fi
    if $ok; then
      printf '  <item label="%s">\n' "$(esc "${name:-$token}")"
      printf '    <action name="Execute">\n'
      # Emit the original Exec so placeholders/args remain (Openbox will run it via shell)
      printf '      <execute>%s</execute>\n' "$(esc "$execline")"
      printf '    </action>\n'
      printf '  </item>\n'
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name '*.desktop' 2>/dev/null)
done

# Flatpaks
if command -v flatpak >/dev/null 2>&1; then
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    name=$(flatpak info --show-name "$app" 2>/dev/null || echo "$app")
    printf '  <item label="%s (Flatpak)">\n' "$(esc "$name")"
    printf '    <action name="Execute">\n      <execute>flatpak run %s</execute>\n    </action>\n' "$app"
    printf '  </item>\n'
  done < <(flatpak list --app --columns=application 2>/dev/null || true)
fi

printf '  <separator/>\n  <item label="Refresh Dynamic Menu">\n    <action name="Execute">\n      <execute>openbox --reconfigure</execute>\n    </action>\n  </item>\n'
echo '</openbox_pipe_menu>'
