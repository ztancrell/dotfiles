#!/usr/bin/env bash
# Deploy tracked system configs from ~/etc/ to /etc/
# Usage: sudo ~/etc/install.sh [relative-path...]
#
# Examples:
#   sudo ~/etc/install.sh              # deploy everything
#   sudo ~/etc/install.sh ly/config.ini  # deploy one file

set -euo pipefail

SRC="${HOME}/etc"
DEST="/etc"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0 $*" >&2
  exit 1
fi

deploy_path() {
  local rel="$1"
  local src="${SRC}/${rel}"
  local dest="${DEST}/${rel}"

  if [[ ! -e "$src" ]]; then
    echo "skip (missing): $rel" >&2
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  if [[ -d "$src" ]]; then
    cp -a "$src/." "$dest/"
  else
    install -D -m "$(stat -c '%a' "$src")" "$src" "$dest"
  fi
  echo "installed: /etc/$rel"
}

if [[ $# -gt 0 ]]; then
  for rel in "$@"; do
    rel="${rel#/}"
    deploy_path "$rel"
  done
else
  while IFS= read -r -d '' path; do
    rel="${path#${SRC}/}"
    [[ "$rel" == "install.sh" ]] && continue
    [[ "$rel" == README.md ]] && continue
    [[ "$rel" == */README.md ]] && continue
    deploy_path "$rel"
  done < <(find "$SRC" -mindepth 1 -print0)
fi

echo "Done. Review with: sudo diff -ru $SRC $DEST"
