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

grep -Fq 'exec ${self}/apps/${system}/${scriptName} "$@"' \
  "$root/modules/flake/apps.nix"

for app in build-switch clean
do
  test -x "$root/apps/x86_64-linux/$app"
done

for system in aarch64-darwin; do
  for app in build build-switch check-keys clean copy-keys create-keys; do
    test -x "$root/apps/$system/$app"
  done
done

printf '%s\n' 'dendritic-apps=PASS'
