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
wallpapers=${NIXOS_ANYWHERE_WALLPAPERS:-$HOME/Pictures/Wallpapers}
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
if [[ -L $wallpapers || ! -d $wallpapers ]]; then
  printf 'wallpaper source must be a real directory: %s\n' "$wallpapers" >&2
  exit 1
fi
unsupported=$(find -P "$wallpapers" -xdev -mindepth 1 ! -type f ! -type d -print -quit)
if [[ -n $unsupported ]]; then
  printf 'wallpaper source contains a symlink or special file: %s\n' "$unsupported" >&2
  exit 1
fi
read -r wallpapers_kib _ < <(
  du --apparent-size --block-size=1024 --summarize --one-file-system -- "$wallpapers"
)
wallpapers_limit_kib=$((4 * 1024 * 1024))
if (( wallpapers_kib > wallpapers_limit_kib )); then
  printf 'wallpaper source exceeds the 4 GiB install limit: %s\n' "$wallpapers" >&2
  exit 1
fi
runtime_available_kib=$(df -Pk -- "$runtime" | awk 'NR == 2 { print $4 }')
if (( wallpapers_kib + 65536 > runtime_available_kib )); then
  printf 'XDG_RUNTIME_DIR lacks space to stage wallpapers: need %s KiB plus 65536 KiB reserve\n' \
    "$wallpapers_kib" >&2
  exit 1
fi

terminate_tree() {
  local root=$1 child children=
  if [[ -r /proc/$root/task/$root/children ]]; then
    read -r children < "/proc/$root/task/$root/children" || true
  fi
  for child in $children; do
    terminate_tree "$child"
  done
  kill -TERM "$root" 2>/dev/null || true
}

terminate_installer() {
  if [[ -n $installer_pid ]] && kill -0 "$installer_pid" 2>/dev/null; then
    terminate_tree "$installer_pid"
    wait "$installer_pid" 2>/dev/null || true
  fi
}

stage=$(mktemp -d "$runtime/nixos-extra.XXXXXXXX")
installer_pid=
trap 'terminate_installer; rm -rf -- "$stage"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

install -d -m 700 "$stage/var/lib/nixos-bootstrap"
hash_file="$stage/var/lib/nixos-bootstrap/mei-password.hash"
install -d -m 755 "$stage/home/mei/Pictures/Wallpapers"
cp -a -x -- "$wallpapers/." "$stage/home/mei/Pictures/Wallpapers/"

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

exec {installer_stdin}<&0
env -u SSH_AUTH_SOCK \
  nix run "github:nix-community/nixos-anywhere/$nixos_anywhere_rev" -- \
  --flake "$flake" \
  --target-host "$target" \
  --ssh-option IdentityAgent=none \
  --build-on local \
  --extra-files "$stage" \
  --chown var/lib/nixos-bootstrap 0:0 \
  --chown home/mei/Pictures 1000:100 \
  --no-substitute-on-destination \
  --option max-jobs 1 \
  --option cores 1 \
  <&"$installer_stdin" &
installer_pid=$!
exec {installer_stdin}<&-

set +e
wait "$installer_pid"
status=$?
set -e
installer_pid=
exit "$status"
