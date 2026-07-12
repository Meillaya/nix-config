#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'usage: nixos-anywhere-bootstrap-password.fish TARGET [FLAKE]' \
    'example: nixos-anywhere-bootstrap-password.fish root@192.168.1.123 .#x86_64-linux' \
    >&2
}

if (( $# < 1 || $# > 2 )); then
  usage
  exit 2
fi

target=$1
flake=${2:-.#x86_64-linux}
nixpkgs_rev=59e69648d345d6e8fef86158c555730fa12af9de
nixos_anywhere_rev=4dfb813db065afb0aba1f61658ef77993d382db1
runtime=${XDG_RUNTIME_DIR:-}
if [[ -z $runtime ]]; then
  printf '%s\n' 'XDG_RUNTIME_DIR is not set' >&2
  exit 1
fi
if [[ $(findmnt -no FSTYPE --target "$runtime") != tmpfs ]]; then
  printf '%s\n' 'XDG_RUNTIME_DIR must be on tmpfs' >&2
  exit 1
fi

stage=$(mktemp -d "$runtime/nixos-extra.XXXXXXXX")
installer_pid=
trap 'if [[ -n $installer_pid ]] && kill -0 "$installer_pid" 2>/dev/null; then kill -TERM -- "-$installer_pid" 2>/dev/null || true; wait "$installer_pid" 2>/dev/null || true; fi; rm -rf -- "$stage"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

install -d -m 700 "$stage/var/lib/nixos-bootstrap"
hash_file="$stage/var/lib/nixos-bootstrap/mei-password.hash"

nix shell "github:NixOS/nixpkgs/$nixpkgs_rev#mkpasswd" \
  --command mkpasswd --method=yescrypt > "$hash_file"
chmod 600 "$hash_file"

last_byte=$(tail -c 1 "$hash_file" | od -An -tuC | tr -d '[:space:]')
yescrypt_pattern="^\\\$y\\\$[./A-Za-z0-9]+\\\$[./A-Za-z0-9]{1,86}\\\$[./A-Za-z0-9]{43}$"
if [[ $last_byte != 10 ]] \
  || [[ $(wc -l < "$hash_file") -ne 1 ]] \
  || ! grep -Eqx "$yescrypt_pattern" "$hash_file"; then
  printf '%s\n' 'mkpasswd did not produce one newline-terminated yescrypt hash' >&2
  exit 1
fi

setsid nix run "github:nix-community/nixos-anywhere/$nixos_anywhere_rev" -- \
  --flake "$flake" \
  --target-host "$target" \
  --build-on local \
  --extra-files "$stage" \
  --option max-jobs 1 \
  --option cores 1 &
installer_pid=$!

set +e
wait "$installer_pid"
status=$?
set -e
installer_pid=
exit "$status"
