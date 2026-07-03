#!/usr/bin/env bash
# redshift-tray: redshift launcher with minimal tray icon + GeoClue2/IP fallback
# Usage: ~/bin/redshift-tray [start|stop|restart|status]  (default: start)
set -euo pipefail

RED_SHIFT_CMD=$(command -v redshift || true)
PYTHON=$(command -v python3 || true)

if [[ -z "$RED_SHIFT_CMD" ]]; then
  echo "redshift not found. Install 'redshift'." >&2
  exit 2
fi
if [[ -z "$PYTHON" ]]; then
  echo "python3 not found. Install Python 3 and PyGObject." >&2
  exit 2
fi

ACTION="${1:-start}"
export REDSHIFT_LAUNCHER="$(realpath "$0")"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/redshift-tray"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/redshift-tray"
mkdir -p "$CACHE_DIR" "$RUNTIME_DIR"
TMPDIR="$RUNTIME_DIR"
PYCODE="$CACHE_DIR/tray.py"
ICON_DAY="$CACHE_DIR/icon-day.svg"
ICON_NIGHT="$CACHE_DIR/icon-night.svg"
ICON_NEUTRAL="$CACHE_DIR/icon-neutral.svg"
export REDSHIFT_ICON_DIR="$CACHE_DIR"
COORDS_CACHE="$CACHE_DIR/coords"
REDSHIFT_CONF="$RUNTIME_DIR/redshift.conf"

write_file_if_missing() {
  local path=$1
  [[ -f "$path" ]] && return 0
  cat > "$path"
}

# Embedded minimal SVG icons (day/night/neutral) — clean, flat shapes
write_file_if_missing "$ICON_DAY" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <circle cx="32" cy="32" r="12" fill="#ffc857"/>
  <g stroke="#ffc857" stroke-width="2" stroke-linecap="round">
    <line x1="32" y1="4" x2="32" y2="14"/>
    <line x1="32" y1="50" x2="32" y2="60"/>
    <line x1="4" y1="32" x2="14" y2="32"/>
    <line x1="50" y1="32" x2="60" y2="32"/>
    <line x1="12" y1="12" x2="18" y2="18"/>
    <line x1="46" y1="46" x2="52" y2="52"/>
    <line x1="12" y1="52" x2="18" y2="46"/>
    <line x1="46" y1="18" x2="52" y2="12"/>
  </g>
</svg>
SVG

write_file_if_missing "$ICON_NIGHT" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <path d="M44 16c-12 0-20 10-20 22 0 8 6 14 14 14 12 0 22-8 22-22C60 22 54 16 44 16z" fill="#6b8cff"/>
</svg>
SVG

write_file_if_missing "$ICON_NEUTRAL" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <circle cx="32" cy="32" r="14" fill="#9aa5b1"/>
</svg>
SVG

# ---------- Location detection (GeoClue2 via gdbus -> IP fallback) ----------
get_geoclue_coords() {
  if command -v gdbus >/dev/null 2>&1; then
    local resp client_path loc loc_path lat_raw lon_raw lat lon
    resp=$(gdbus call --session \
      --dest org.freedesktop.GeoClue2 \
      --object-path /org/freedesktop/GeoClue2/Manager \
      --method org.freedesktop.GeoClue2.Manager.GetClient 2>/dev/null) || return 1
    client_path=${resp#*\'}
    client_path=${client_path%%\'*}
    [[ "$client_path" == /* ]] || return 1
    [[ -z "$client_path" ]] && return 1
    # set DesktopId (some setups require)
    gdbus call --session --dest org.freedesktop.GeoClue2 --object-path "$client_path" \
      --method org.freedesktop.DBus.Properties.Set org.freedesktop.GeoClue2.Client "DesktopId" "s" "redshift-tray" >/dev/null 2>&1 || true
    loc=$(gdbus call --session --dest org.freedesktop.GeoClue2 --object-path "$client_path" \
      --method org.freedesktop.GeoClue2.Client.GetLocation 2>/dev/null) || return 1
    loc_path=${loc#*\'}
    loc_path=${loc_path%%\'*}
    [[ "$loc_path" == /* ]] || return 1
    [[ -z "$loc_path" ]] && return 1
    lat_raw=$(gdbus call --session --dest org.freedesktop.GeoClue2 --object-path "$loc_path" \
      --method org.freedesktop.DBus.Properties.Get org.freedesktop.GeoClue2.Location Latitude 2>/dev/null) || return 1
    lon_raw=$(gdbus call --session --dest org.freedesktop.GeoClue2 --object-path "$loc_path" \
      --method org.freedesktop.DBus.Properties.Get org.freedesktop.GeoClue2.Location Longitude 2>/dev/null) || return 1
    [[ "$lat_raw" =~ (-?[0-9]+([.][0-9]+)?) ]] || return 1
    lat=${BASH_REMATCH[1]}
    [[ "$lon_raw" =~ (-?[0-9]+([.][0-9]+)?) ]] || return 1
    lon=${BASH_REMATCH[1]}
    [[ -n "$lat" && -n "$lon" ]] && printf "%s %s" "$lat" "$lon" && return 0
  fi
  return 1
}

get_ip_coords() {
  local data lat lon loc endpoint
  if command -v curl >/dev/null 2>&1; then
    for endpoint in "https://ipapi.co/json" "https://ipinfo.io/json"; do
      data=$(curl -fsS --max-time 2 "$endpoint" 2>/dev/null) || continue
      lat=""; lon=""
      if [[ "$data" =~ \"latitude\"[[:space:]]*:[[:space:]]*(-?[0-9]+([.][0-9]+)?) ]]; then
        lat=${BASH_REMATCH[1]}
      fi
      if [[ "$data" =~ \"longitude\"[[:space:]]*:[[:space:]]*(-?[0-9]+([.][0-9]+)?) ]]; then
        lon=${BASH_REMATCH[1]}
      fi
      if [[ -z "$lat" || -z "$lon" ]]; then
        if [[ "$data" =~ \"loc\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
          loc=${BASH_REMATCH[1]}
        else
          loc=""
        fi
        if [[ -n "$loc" && "$loc" == *","* ]]; then
          lat=${loc%%,*}; lon=${loc##*,}
        fi
      fi
      if [[ -n "$lat" && -n "$lon" ]]; then
        printf "%s %s" "$lat" "$lon"
        return 0
      fi
    done
  fi
  return 1
}

detect_coords() {
  local coords
  if [[ -n "${LAT:-}" && -n "${LON:-}" ]]; then
    printf "%s %s" "$LAT" "$LON"; return 0
  fi
  if coords=$(get_geoclue_coords 2>/dev/null); then
    printf "%s\n" "$coords" > "$COORDS_CACHE"
    printf "%s" "$coords"
    return 0
  fi
  if coords=$(get_ip_coords 2>/dev/null); then
    printf "%s\n" "$coords" > "$COORDS_CACHE"
    printf "%s" "$coords"
    return 0
  fi
  if [[ -s "$COORDS_CACHE" ]]; then
    read -r coords < "$COORDS_CACHE"
    printf "%s" "$coords"
    return 0
  fi
  printf "0 0"; return 0
}

write_runtime_conf() {
  local lat=$1 lon=$2
  cat > "$REDSHIFT_CONF" <<EOF
[redshift]
temp-day=6500
temp-night=3700
gamma=0.8
location-provider=manual
adjustment-method=randr

[manual]
lat=$lat
lon=$lon
EOF
}

start_redshift_bg() {
  local lat lon
  if pgrep -x redshift >/dev/null 2>&1; then return 0; fi
  read -r lat lon <<< "$(detect_coords)"
  write_runtime_conf "$lat" "$lon"
  REDSHIFT_CONFIG="$REDSHIFT_CONF" nohup "$RED_SHIFT_CMD" -c "$REDSHIFT_CONF" >/dev/null 2>&1 &
  sleep 0.2
}

stop_redshift_bg() {
  if pgrep -x redshift >/dev/null 2>&1; then
    pkill -x redshift >/dev/null 2>&1 || true
    sleep 0.2
  fi
}

status_redshift_cli() {
  local state has_gdbus has_curl has_pgrep has_pkill pids
  local conf_lat="?" conf_lon="?" conf_exists="no"
  local cache_coords="none"
  local now

  now=$(date '+%Y-%m-%d %H:%M:%S %Z')
  has_gdbus=$(command -v gdbus >/dev/null 2>&1 && echo "yes" || echo "no")
  has_curl=$(command -v curl >/dev/null 2>&1 && echo "yes" || echo "no")
  has_pgrep=$(command -v pgrep >/dev/null 2>&1 && echo "yes" || echo "no")
  has_pkill=$(command -v pkill >/dev/null 2>&1 && echo "yes" || echo "no")

  if pgrep -x redshift >/dev/null 2>&1; then
    state="running"
    pids=$(pgrep -x redshift | tr '\n' ' ' | sed 's/[[:space:]]\+$//')
  else
    state="stopped"
    pids="none"
  fi

  if [[ -f "$REDSHIFT_CONF" ]]; then
    conf_exists="yes"
    conf_lat=$(awk -F= '/^lat=/{print $2; exit}' "$REDSHIFT_CONF" 2>/dev/null || printf "?")
    conf_lon=$(awk -F= '/^lon=/{print $2; exit}' "$REDSHIFT_CONF" 2>/dev/null || printf "?")
  fi

  if [[ -s "$COORDS_CACHE" ]]; then
    read -r cache_coords < "$COORDS_CACHE"
  fi

  printf "time: %s\n" "$now"
  printf "state: %s\n" "$state"
  printf "pids: %s\n" "$pids"
  if [[ "$state" == "running" ]]; then
    ps -o pid=,etime=,args= -C redshift 2>/dev/null | sed 's/^/process: /' || true
  fi
  printf "script: %s\n" "$REDSHIFT_LAUNCHER"
  printf "redshift_bin: %s\n" "$RED_SHIFT_CMD"
  printf "python_bin: %s\n" "$PYTHON"
  printf "runtime_dir: %s\n" "$RUNTIME_DIR"
  printf "cache_dir: %s\n" "$CACHE_DIR"
  printf "config_file: %s (exists=%s)\n" "$REDSHIFT_CONF" "$conf_exists"
  printf "config_coords: lat=%s lon=%s\n" "$conf_lat" "$conf_lon"
  printf "cached_coords: %s\n" "$cache_coords"
  printf "env_coords: LAT=%s LON=%s\n" "${LAT:-unset}" "${LON:-unset}"
  printf "deps: gdbus=%s curl=%s pgrep=%s pkill=%s\n" "$has_gdbus" "$has_curl" "$has_pgrep" "$has_pkill"
}

# ---------- Python tray app (embedded) ----------
if [[ ! -f "$PYCODE" || "$REDSHIFT_LAUNCHER" -nt "$PYCODE" ]]; then
cat > "$PYCODE" <<'PY'
#!/usr/bin/env python3
# Minimal tray indicator controlling redshift (Start/Stop/Restart/Status/Quit)
import os,sys,subprocess,time
from pathlib import Path

# Prefer GTK 3 / AppIndicator3 (Gtk4 lacks Gtk.Menu / StatusIcon API used below)
try:
    from gi import require_version
    require_version('Gtk', '3.0')
    try:
        require_version('AppIndicator3', '0.1')
    except Exception:
        # AppIndicator may be absent; we'll fall back to Gtk.StatusIcon if available
        pass
except Exception:
    pass

try:
    from gi.repository import GLib, Gtk
    have_gi = True
except Exception:
    have_gi = False

APPIND = False
try:
    from gi.repository import AppIndicator3
    APPIND = True
except Exception:
    APPIND = False

ICON_DIR = sys.argv[1]
ICON_DAY = str(Path(ICON_DIR)/"icon-day.svg")
ICON_NIGHT = str(Path(ICON_DIR)/"icon-night.svg")
ICON_NEUT = str(Path(ICON_DIR)/"icon-neutral.svg")
# Fallback to cached icon dir if runtime path does not contain icons.
if not Path(ICON_NEUT).exists():
    fallback_dir = os.environ.get('REDSHIFT_ICON_DIR')
    if fallback_dir:
        ICON_DAY = str(Path(fallback_dir)/"icon-day.svg")
        ICON_NIGHT = str(Path(fallback_dir)/"icon-night.svg")
        ICON_NEUT = str(Path(fallback_dir)/"icon-neutral.svg")
LAUNCHER = os.environ.get('REDSHIFT_LAUNCHER')
EXEC = os.environ.get('REDSHIFT_CMD','redshift')

def run_cmd(args):
    try:
        out = subprocess.check_output(args, stderr=subprocess.STDOUT, text=True)
        return out.strip()
    except subprocess.CalledProcessError as e:
        return e.output.strip() if e.output else str(e)

def invoke_launcher(action):
    if not LAUNCHER:
        return
    try:
        subprocess.Popen([LAUNCHER, f"internal-{action}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def menu_action(action):
    if action=='start':
        invoke_launcher('start')
    elif action=='stop':
        invoke_launcher('stop')
    elif action=='restart':
        invoke_launcher('stop')
        time.sleep(0.2)
        invoke_launcher('start')
    elif action=='status':
        out = "status unavailable"
        if LAUNCHER:
            try:
                out = subprocess.check_output([LAUNCHER, 'status'], stderr=subprocess.STDOUT, text=True, timeout=5).strip()
            except Exception as exc:
                out = f"status failed: {exc}"
        dlg = Gtk.MessageDialog(message_format="redshift status", buttons=Gtk.ButtonsType.OK)
        dlg.format_secondary_text(out)
        dlg.connect('response', lambda d,r: d.destroy())
        dlg.show_all()
    elif action=='quit':
        Gtk.main_quit()

# Handle direct internal-* invocations (when Python file is executed by launcher)
if len(sys.argv)>1 and sys.argv[1].startswith('internal-'):
    # forward to the bash wrapper so the bash-side functions run
    action = sys.argv[1].split('-',1)[1]
    invoke_launcher(action)
    sys.exit(0)

if not have_gi:
    print("Missing PyGObject (gi). Tray disabled.", file=sys.stderr)
    sys.exit(1)

def build_menu():
    menu = Gtk.Menu()
    for key,label in [('start','Start'),('stop','Stop'),('restart','Restart'),('status','Status'),('quit','Quit')]:
        item = Gtk.MenuItem(label=label)
        item.connect('activate', lambda w,k=key: menu_action(k))
        menu.append(item)
    menu.show_all()
    return menu

# color blending / animated icon update
from xml.etree import ElementTree as ET
import math
UPDATE_MS = 2000

# base colors (hex)
DAY_COLOR = "#ffc857"
NIGHT_COLOR = "#6b8cff"
NEUTRAL_COLOR = "#9aa5b1"  # kept for future style tweaks

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2],16) for i in (0,2,4))

def rgb_to_hex(rgb):
    return '#%02x%02x%02x' % tuple(max(0,min(255,int(round(c)))) for c in rgb)

def blend(c1, c2, t):
    r1,g1,b1 = hex_to_rgb(c1); r2,g2,b2 = hex_to_rgb(c2)
    return rgb_to_hex((r1+(r2-r1)*t, g1+(g2-g1)*t, b1+(b2-b1)*t))

def day_night_factor():
    # 0.0 = day, 1.0 = night (smooth)
    tm = time.localtime()
    h = tm.tm_hour + tm.tm_min/60.0
    # center day ~13:00, night ~1:00 — smooth cosine transition
    angle = ((h - 7.0) / 24.0) * 2.0 * math.pi
    v = (1 - math.cos(angle)) / 2.0
    return v

def create_blended_svg(template_path, out_path, fill_color):
    try:
        tree = ET.parse(template_path)
        root = tree.getroot()
        for el in root.iter():
            if 'fill' in el.attrib:
                el.set('fill', fill_color)
        tree.write(out_path)
    except Exception:
        import shutil
        shutil.copy(template_path, out_path)

# temp blended icon path
BLEND_ICON = str(Path(ICON_DIR)/"icon-blend.svg")

def update_icon_tick():
    t = day_night_factor()
    color = blend(DAY_COLOR, NIGHT_COLOR, t)
    create_blended_svg(ICON_NEUT, BLEND_ICON, color)
    if APPIND:
        try:
            indicator.set_icon_full(BLEND_ICON, "redshift")
        except Exception:
            pass
    else:
        try:
            tray.set_from_file(BLEND_ICON)
        except Exception:
            pass
    return True

def schedule_updates():
    try:
        GLib.timeout_add(UPDATE_MS, update_icon_tick)
    except Exception:
        pass

def main():
    global indicator, tray
    menu = build_menu()
    if APPIND:
        indicator = AppIndicator3.Indicator.new("redshift-tray", ICON_NEUT, AppIndicator3.IndicatorCategory.APPLICATION_STATUS)
        indicator.set_status(AppIndicator3.IndicatorStatus.ACTIVE)
        indicator.set_menu(menu)
    else:
        tray = Gtk.StatusIcon()
        tray.set_visible(True)
        tray.connect('popup-menu', lambda icon,event: menu.popup_at_pointer(None))
    # start animated updates (this will create and set the blended icon)
    schedule_updates()
    Gtk.main()

if __name__=='__main__':
    main()
PY
fi

chmod +x "$PYCODE"

# helper wrapper to run internal start/stop in background (keeps bash logic here)
if [[ "${ACTION}" == internal-start ]]; then
  start_redshift_bg
  exit 0
fi
if [[ "${ACTION}" == internal-stop ]]; then
  stop_redshift_bg
  exit 0
fi

case "$ACTION" in
  start)
    start_redshift_bg
    # export redshift command path for python helper if needed
    export REDSHIFT_CMD="$RED_SHIFT_CMD"
    # launch tray (keep in foreground)
    "$PYTHON" "$PYCODE" "$CACHE_DIR"
    ;;
  stop)
    stop_redshift_bg
    ;;
  restart)
    stop_redshift_bg
    start_redshift_bg
    ;;
  status)
    status_redshift_cli
    ;;
  *)
    echo "Usage: $0 [start|stop|restart|status]" >&2
    exit 2
    ;;
esac
