#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

python3 - <<'PY'
import datetime as dt
import json
from pathlib import Path

policy = json.loads(Path("config/package-exceptions.json").read_text())
assert policy["schemaVersion"] == 1
rows = policy["exceptions"]
pnames = [row["pname"] for row in rows]
assert pnames == sorted(pnames)
assert len(pnames) == len(set(pnames))
allowed_systems = {"x86_64-linux", "aarch64-linux", "aarch64-darwin"}
for row in rows:
    assert set(row) == {
        "pname", "owner", "reason", "reviewedAt", "expiresAt",
        "maxTtlDays", "systems",
    }
    assert row["owner"] == "maintainer"
    assert row["reason"]
    reviewed = dt.date.fromisoformat(row["reviewedAt"])
    expires = dt.date.fromisoformat(row["expiresAt"])
    assert row["maxTtlDays"] == 90
    assert (expires - reviewed).days <= row["maxTtlDays"]
    assert row["systems"] == sorted(set(row["systems"]))
    assert set(row["systems"]) <= allowed_systems

outputs = json.loads(Path("config/release-outputs.json").read_text())
assert outputs == {
    "schemaVersion": 1,
    "release": [
        "darwinConfigurations.aarch64-darwin",
        "homeConfigurations.standalone-linux",
        "homeConfigurations.standalone-linux-aarch64",
        "nixosConfigurations.aarch64-linux",
        "nixosConfigurations.x86_64-linux",
    ],
    "qualificationOnly": ["nixosConfigurations.nixos-x86-qualifier"],
}
PY

if grep -Eq 'allow(Unfree|Broken|UnsupportedSystem)[[:space:]]*=[[:space:]]*true' lib/nixpkgs.nix; then
  echo "global Nixpkgs escape is enabled" >&2
  exit 1
fi
grep -Fq 'permittedInsecurePackages = [ ];' lib/nixpkgs.nix

if grep -R -Fq '%DISK%' modules config; then
  echo "generic destructive disk placeholder remains" >&2
  exit 1
fi
for value in \
  'size = "1G"' \
  'format = "vfat"' \
  '"@root"' \
  '"@home"' \
  '"@nix"' \
  '"@log"' \
  'compress=zstd:3' \
  'configurationLimit = 10'
do
  grep -R -Fq "$value" modules/nixos
done

grep -Fq 'nixos-x86-qualifier' modules/entities/hosts.nix
grep -Fq 'role = "evaluation"' config/hosts.nix
if grep -Eq 'identity|home|uid|gid|timeZone|America/' config/hosts.nix; then
  echo "public host registry contains personal identity or location fields" >&2
  exit 1
fi
if grep -Eq 'x86_64-darwin' modules/entities/hosts.nix modules/flake/systems.nix; then
  echo "Intel Darwin is still exposed" >&2
  exit 1
fi

for unsafe in linuxPackages_latest 'windowManager.bspwm' 'services.picom'; do
  if grep -R -Fq "$unsafe" modules/aspects modules/nixos modules/entities; then
    echo "retired platform/session policy remains: $unsafe" >&2
    exit 1
  fi
done

catalog=modules/shared/application-packages.nix
for package in \
  aria2 bat bitwarden-desktop bruno btop bun cmake conky curl dbeaver-bin \
  docker eza fastfetch fd ffmpeg flameshot fsearch fzf git go halloy helix \
  hoppscotch htop imhex incus jetbrains.idea jetbrains.pycharm keepassxc \
  kubectl lazygit llama-cpp meld micro mission-center ncdu neovim nodejs_24 \
  obs-studio ollama opencode openrgb kdePackages.partitionmanager pnpm podman \
  postman ptyxis python3 ranger restic ripgrep rsync rustup sublime4 superfile \
  tldr tmux uv vagrant vesktop virt-manager wget wireshark yaak yazi zed-editor \
  zellij zoxide
do
  grep -Fq "$package" "$catalog" || {
    echo "requested application missing from catalog: $package" >&2
    exit 1
  }
done

grep -Fq 'OMX_AUTO_UPDATE=0' modules/shared/packages.nix
if grep -Eq 'sync-ai-sidecars|npm_root|/opt/(homebrew|zerobrew)' modules/shared/packages.nix; then
  echo "AI command has a mutable fallback owner" >&2
  exit 1
fi

grep -Fq 'v3.21.0' bin/install-determinate-nix
grep -Fq 'b9911496659f0c35c642353d592926c024c205b597e8094bf73a42908a75e462' bin/install-determinate-nix
grep -Fq 'd2ede080a0a7b34119362f4a8a6fb5e49a4d16b302ce54c96cd05514bdea6c7c' bin/install-determinate-nix
grep -Fq 'export NIX_CONFIG_PROFILE=wsl' modules/flake/apps.nix

printf '%s\n' 'machine-readiness-foundation=PASS'
