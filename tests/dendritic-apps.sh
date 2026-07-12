#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/dendritic-apps.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT

awk '
  /<<'\''PY'\''$/ { capture = 1; next }
  capture && /^PY$/ { exit }
  capture { print }
' "$root/modules/flake/apps.nix" > "$tmpdir/linux-home-sources.py"

test -s "$tmpdir/linux-home-sources.py"
python3 -m py_compile "$tmpdir/linux-home-sources.py"

printf '%s\n' 'dendritic-apps=PASS'
