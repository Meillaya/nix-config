#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

grep -Fq 'inputs.flake-parts.lib.mkFlake' flake.nix
grep -Fq 'inputs.import-tree ./modules' flake.nix
grep -Fq 'github:denful/den/1614f6f8ed435c5bb257408bf91fd662f9aac43e' flake.nix

for path in \
  modules/flake/dendritic.nix \
  modules/flake/outputs.nix \
  modules/entities/hosts.nix \
  modules/aspects/users/mei.nix \
  modules/aspects/hosts/nixos-workstation.nix \
  modules/aspects/hosts/darwin-workstation.nix
do
  test -f "$path"
done

if ! test -f modules/shared/config/fastfetch/snoopy-mugiwara.png; then
  echo 'Darwin Fastfetch profile is missing the configured Snoopy logo asset' >&2
  exit 1
fi

grep -Fq '"source": "~/.config/fastfetch/snoopy-mugiwara.png"' \
  modules/shared/config/fastfetch/config.jsonc

fastfetch_home=$(mktemp -d "${TMPDIR:-/tmp}/fastfetch-profile.XXXXXX")
fastfetch_output=$(mktemp "${TMPDIR:-/tmp}/fastfetch-output.XXXXXX")
trap 'rm -rf "$fastfetch_home" "$fastfetch_output"' EXIT
mkdir -p "$fastfetch_home/.config"
cp -R modules/shared/config/fastfetch "$fastfetch_home/.config/fastfetch"

HOME="$fastfetch_home" TERM=xterm-kitty KITTY_WINDOW_ID=1 \
  fastfetch \
    --config "$fastfetch_home/.config/fastfetch/config.jsonc" \
    --pipe false \
    --structure OS > "$fastfetch_output"

if ! grep -aFq 'a=T,f=100,t=f,c=40,r=30' "$fastfetch_output"; then
  echo 'Fastfetch profile did not emit the expected 40x30 direct Kitty image' >&2
  exit 1
fi

if grep -Eq 'nixpkgs\.lib\.nixosSystem|darwin\.lib\.darwinSystem|homeManagerConfiguration' flake.nix; then
  echo 'flake.nix still manually constructs configuration entities' >&2
  exit 1
fi

if grep -R -E 'den\.ctx|mutual-provider|mutualProvider' --include='*.nix' modules flake.nix; then
  echo 'deprecated Den compatibility API detected' >&2
  exit 1
fi

printf '%s\n' 'dendritic-architecture=PASS'
