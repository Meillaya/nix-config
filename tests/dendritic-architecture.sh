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

if grep -Eq 'nixpkgs\.lib\.nixosSystem|darwin\.lib\.darwinSystem|homeManagerConfiguration' flake.nix; then
  echo 'flake.nix still manually constructs configuration entities' >&2
  exit 1
fi

if grep -R -E 'den\.ctx|mutual-provider|mutualProvider' --include='*.nix' modules flake.nix; then
  echo 'deprecated Den compatibility API detected' >&2
  exit 1
fi

printf '%s\n' 'dendritic-architecture=PASS'
