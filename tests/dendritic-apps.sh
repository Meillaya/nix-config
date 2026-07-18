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

for app in build build-switch clean
do
  test -x "$root/apps/x86_64-linux/$app"
done

test -d "$root/apps/aarch64-linux"
test ! -L "$root/apps/aarch64-linux"

for app in build build-switch clean home-news home-switch search-pkgs update
do
  test -x "$root/apps/aarch64-linux/$app"
done
test -x "$root/apps/linux/sync-secrets"

for system in x86_64-linux aarch64-linux; do
  app_names=$(nix eval --impure --json --expr \
    "builtins.attrNames (builtins.getFlake \"path:$root\").apps.$system")
  python3 - "$system" "$app_names" <<'PY'
import json
import sys

system = sys.argv[1]
apps = json.loads(sys.argv[2])
assert apps == [
    "build",
    "home-news",
    "home-switch",
    "search-pkgs",
    "sync-secrets",
    "update",
], (system, apps)
assert "build-switch" not in apps
assert "clean" not in apps
PY
done

if grep -R -E \
  'nixos-rebuild[[:space:]]+(switch|boot)|nix-collect-garbage|--delete-older-than|--install-bootloader' \
  "$root/apps/x86_64-linux/build" \
  "$root/apps/x86_64-linux/build-switch" \
  "$root/apps/x86_64-linux/clean" \
  "$root/apps/aarch64-linux/build" \
  "$root/apps/aarch64-linux/build-switch" \
  "$root/apps/aarch64-linux/clean"
then
  echo 'evaluation or pending Linux app scripts retain a boot-mutating path' >&2
  exit 1
fi

if grep -F -- '--impure' \
  "$root/modules/flake/apps.nix" \
  "$root/apps/aarch64-linux/home-switch" \
  "$root/apps/aarch64-linux/home-news" \
  "$root/README.md" \
  "$root/docs/service-notes/wsl-standalone-home-manager.md"
then
  echo 'production standalone Home Manager path still requests impure evaluation' >&2
  exit 1
fi

if grep -E 'NIXOS_CONFIG_(USER|HOME)|builtins\.getEnv' \
  "$root/modules/standalone-linux/home-manager.nix" \
  "$root/apps/aarch64-linux/home-switch" \
  "$root/apps/aarch64-linux/home-news" \
  "$root/README.md" \
  "$root/docs/service-notes/wsl-standalone-home-manager.md"
then
  echo 'production standalone path still accepts ambient identity' >&2
  exit 1
fi

for app in build build-switch check-keys clean copy-keys create-keys; do
  test -x "$root/apps/aarch64-darwin/$app"
done

darwin_apps=$(nix eval --impure --json --expr \
  "builtins.attrNames (builtins.getFlake \"path:$root\").apps.aarch64-darwin")
python3 - "$darwin_apps" <<'PY'
import json
import sys

assert json.loads(sys.argv[1]) == ["build", "search-pkgs"]
PY

grep -Fq 'darwinMachinesFor = system:' "$root/modules/flake/apps.nix"
grep -Fq 'validatedMachines' "$root/modules/flake/apps.nix"
grep -Fq 'machineAuthority.allowsSystemMutation' "$root/modules/flake/apps.nix"
grep -Fq 'machineAuthority.allowsCredentialMutation' "$root/modules/flake/apps.nix"
if grep -E '\$\{?USER|builtins\.getEnv' "$root"/apps/aarch64-darwin/{check-keys,copy-keys,create-keys}; then
  echo 'Darwin credential scripts still select ambient evaluator/operator identity' >&2
  exit 1
fi
grep -Fq 'NIX_CONFIG_USER_NAME' "$root/apps/aarch64-darwin/check-keys"
grep -Fq 'NIX_CONFIG_USER_NAME' "$root/apps/aarch64-darwin/copy-keys"
grep -Fq 'NIX_CONFIG_USER_NAME' "$root/apps/aarch64-darwin/create-keys"

test ! -e "$root/apps/x86_64-darwin"

darwin_app_systems=$(nix eval --impure --json --expr \
  "builtins.attrNames (builtins.getFlake \"path:$root\").apps")
python3 - "$darwin_app_systems" <<'PY'
import json
import sys

systems = json.loads(sys.argv[1])
assert "aarch64-darwin" in systems
assert "x86_64-darwin" not in systems
PY

printf '%s\n' 'dendritic-apps=PASS'
