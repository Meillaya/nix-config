#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

grep -Fq 'inputs.flake-parts.lib.mkFlake' flake.nix
grep -Fq 'inputs.import-tree ./modules' flake.nix
grep -Fq 'github:denful/den/1614f6f8ed435c5bb257408bf91fd662f9aac43e' flake.nix
grep -Fq 'inputs.den.flakeModules.strict' modules/flake/dendritic.nix
grep -Fq 'options.homeDirectory = lib.mkOption' modules/entities/defaults.nix
grep -Fq 'options.machine = lib.mkOption' modules/entities/defaults.nix
grep -Fq 'options.identity = lib.mkOption' modules/entities/defaults.nix
grep -Fq 'machineType = lib.types.submodule' modules/entities/defaults.nix

if grep -A2 -F 'options.machine = lib.mkOption' modules/entities/defaults.nix \
  | grep -Eq 'type = lib\.types\.(attrs|raw);'; then
  echo 'host/home machine schema is still generic attrs/raw' >&2
  exit 1
fi

if grep -A2 -F 'options.identity = lib.mkOption' modules/entities/defaults.nix \
  | grep -Eq 'type = lib\.types\.(attrs|raw);'; then
  echo 'user identity schema is still generic attrs/raw' >&2
  exit 1
fi
grep -A2 -F 'options.identity = lib.mkOption' modules/entities/defaults.nix \
  | grep -Fq 'type = identityType;'

for path in \
  modules/flake/dendritic.nix \
  modules/flake/outputs.nix \
  modules/entities/machine-authority.nix \
  modules/entities/hosts.nix \
  modules/entities/_machine-authority/model.nix \
  modules/entities/_machine-authority/validators.nix \
  modules/aspects/shared-policy/nixpkgs.nix \
  modules/aspects/platforms/linux.nix \
  modules/aspects/platforms/darwin.nix \
  modules/aspects/roles/workstation-linux.nix \
  modules/aspects/roles/workstation-darwin.nix \
  modules/aspects/hardware/pending-x86-workstation.nix \
  modules/aspects/hardware/evaluation-aarch64.nix \
  modules/aspects/hardware/apple-silicon.nix \
  modules/aspects/storage/nixos-laptop.nix \
  modules/aspects/storage/aarch64-linux.nix \
  modules/aspects/storage/aarch64-darwin.nix \
  modules/aspects/named-hosts/nixos-laptop.nix \
  modules/aspects/named-hosts/aarch64-linux.nix \
  modules/aspects/named-hosts/aarch64-darwin.nix \
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

if grep -Eq 'nixpkgsPolicy|pkgs[[:space:]]*=' modules/entities/hosts.nix; then
  echo 'Den entity declarations contain non-identity package policy' >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*(aspect|includes|nixos|darwin|homeManager)[[:space:]]*=' \
  modules/entities/hosts.nix; then
  echo 'Den entity declarations contain behavior or aspect selection' >&2
  exit 1
fi

if grep -R -Fq 'x86_64-darwin' \
  modules/entities/hosts.nix modules/flake/systems.nix \
  modules/flake/apps.nix modules/aspects/hosts/darwin-workstation.nix; then
  echo 'unsupported x86_64-darwin output remains in the Dendritic graph' >&2
  exit 1
fi

test ! -e apps/x86_64-darwin

if [[ -v DENDRITIC_DARWIN_CONFIGURATION_SYSTEMS ]]; then
  darwin_configuration_systems=$DENDRITIC_DARWIN_CONFIGURATION_SYSTEMS
else
  darwin_configuration_systems=$(nix eval --impure --json --expr \
    "builtins.attrNames (builtins.getFlake \"path:$root\").darwinConfigurations")
fi
python3 - "$darwin_configuration_systems" <<'PY'
import json
import sys

systems = json.loads(sys.argv[1])
assert "aarch64-darwin" in systems
assert "x86_64-darwin" not in systems
PY

grep -Fq 'den.aspects.linux-platform' modules/aspects/platforms/linux.nix
grep -Fq 'den.aspects.workstation-role-linux' modules/aspects/roles/workstation-linux.nix
grep -Fq 'den.aspects.pending-x86-workstation-hardware' \
  modules/aspects/hardware/pending-x86-workstation.nix
grep -Fq 'den.aspects.nixos-laptop-storage' modules/aspects/storage/nixos-laptop.nix
grep -Fq 'den.aspects.nixos-laptop' modules/aspects/named-hosts/nixos-laptop.nix
grep -Fq 'den.aspects.x86_64-linux.includes = [ den.aspects.nixos-laptop ];' \
  modules/aspects/hosts/nixos-workstation.nix

if grep -R -Eq '_machine-authority|authority\.getMachine' \
  modules/aspects/named-hosts \
  modules/aspects/hardware \
  modules/aspects/storage; then
  echo 'host-attached aspects still import global machine authority' >&2
  exit 1
fi

for path in \
  modules/aspects/named-hosts/*.nix \
  modules/aspects/hardware/*.nix \
  modules/aspects/storage/*.nix
do
  grep -Fq 'host.machine' "$path"
done

grep -Fq 'machine.capabilities.values."install.remote".state' \
  modules/aspects/hardware/x86-vendor-routing.nix
if grep -Fq 'machine.capabilities.values.install.remote' \
  modules/aspects/hardware/x86-vendor-routing.nix; then
  echo 'flat install.remote capability key is accessed as nested attributes' >&2
  exit 1
fi

grep -Fq 'system = "x86_64-linux";' modules/entities/hosts.nix
grep -Fq 'system = "aarch64-linux";' modules/entities/hosts.nix
grep -Fq 'home = "/home/mei";' modules/entities/_machine-authority/model.nix

if grep -Eq 'builtins\.getEnv|NIXOS_CONFIG_(USER|HOME)' \
  modules/standalone-linux/home-manager.nix; then
  echo 'standalone Home Manager identity still depends on ambient evaluator state' >&2
  exit 1
fi

grep -Fq 'inherit (home) userName homeDirectory' \
  modules/aspects/hosts/standalone-linux.nix

printf '%s\n' 'dendritic-architecture=PASS'
