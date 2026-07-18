#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if grep -R -E 'specialArgs|extraSpecialArgs' --include='*.nix' flake.nix modules/flake modules/entities modules/aspects; then
  echo 'hidden specialArgs coupling remains in the dendritic graph' >&2
  exit 1
fi

if grep -R -F 'den.batteries.user-shell "nushell"' --include='*.nix' modules; then
  echo 'Den user-shell battery cannot configure Nushell OS modules' >&2
  exit 1
fi

if grep -R -E 'command[[:space:]]*=[[:space:]]*/bin/(fish|zsh|bash)' modules/standalone-linux modules/aspects; then
  echo 'terminal command bypasses the declarative shell package' >&2
  exit 1
fi

if grep -R -E 'Command=.*pkgs\.(fish|zsh|bash)' --include='*.nix' modules; then
  echo 'terminal profile hardcodes a secondary shell' >&2
  exit 1
fi

if test -e hosts/nixos/default.nix || test -e hosts/darwin/default.nix; then
  echo 'legacy host composition entrypoints still exist' >&2
  exit 1
fi

if grep -R -E '^\{[^}]*\buser\b[^}]*\.\.\.' --include='*.nix' modules/aspects/hosts modules/aspects/features; then
  echo 'host-scoped class module requests the silently inert Den user argument' >&2
  exit 1
fi

grep -Fq 'validatedMachines = map machineAuthority.getMachine machineAuthority.machineIds;' \
  modules/flake/apps.nix
if grep -Eq 'machineAuthority\.machines|builtins\.attrValues' modules/flake/apps.nix; then
  echo 'Linux app exposure reads unvalidated machine records' >&2
  exit 1
fi

if grep -Eiw 'polybar|dunst|screen-locker|i3lock|betterlockscreen|swaylock|swaybg|awww|swww|picom|rofi|waybar|mako|wlogout|bspwm|sxhkd' \
  modules/nixos/home-manager.nix \
  modules/nixos/files.nix \
  modules/nixos/niri.nix \
  modules/nixos/packages.nix \
  modules/nixos/system.nix \
  modules/linux/config/niri/config.kdl \
  modules/linux/packages.nix \
  modules/standalone-linux/files.nix; then
  echo 'competing Niri session ownership remains configured' >&2
  exit 1
fi
if grep -R -Eiw 'swaylock|swaybg|wlogout' modules/standalone-linux/config; then
  echo 'standalone configuration retains a competing lock or wallpaper owner' >&2
  exit 1
fi

for module in \
  modules/nixos/home-manager.nix \
  modules/darwin/user-home.nix \
  modules/nixos/system.nix \
  modules/darwin/system.nix \
  modules/darwin/base.nix \
  modules/darwin/secrets.nix \
  modules/nixos/secrets.nix \
  modules/nixos/bootstrap-password.nix \
  modules/standalone-linux/config/noctalia/config.toml
do
  if grep -Eq '"mei"|/home/mei|/Users/mei' "$module"; then
    echo "hardcoded identity remains in active module: $module" >&2
    exit 1
  fi
done

grep -Fq 'host.machine.identity' modules/nixos/system.nix
grep -Fq 'host.machine.identity' modules/darwin/system.nix
grep -Fq 'user.identity' modules/nixos/home-manager.nix
grep -Fq 'user.identity' modules/darwin/user-home.nix
grep -Fq 'host.machine.identity' modules/darwin/base.nix
grep -Fq 'identity.home' modules/darwin/secrets.nix
grep -Fq 'identity.home' modules/nixos/secrets.nix
grep -Fq 'identity.name' modules/nixos/bootstrap-password.nix
grep -Fq 'host.machine.identity' modules/aspects/features/secrets.nix
grep -Fq 'host.machine.identity' modules/aspects/features/bootstrap-password.nix
grep -Fq 'config.home.homeDirectory' modules/aspects/features/noctalia.nix
grep -Fq '@HOME@' modules/standalone-linux/config/noctalia/config.toml

test ! -e modules/aspects/features/nix-core.nix

if grep -Fq 'builtins.getEnv' modules/nixos/files.nix; then
  echo 'NixOS home files depend on the evaluator HOME' >&2
  exit 1
fi

grep -Fq '".config/niri/config.kdl".text' modules/nixos/files.nix
grep -Fq '".config/noctalia/config.toml".text' modules/nixos/files.nix
grep -Fq '[ homeDirectory ]' modules/nixos/files.nix

grep -Fq 'programs.noctalia = {' modules/aspects/features/noctalia.nix
grep -Fq 'systemd.enable = true;' modules/aspects/features/noctalia.nix
grep -Fq 'spawn-sh "noctalia msg screen-lock"' modules/linux/config/niri/config.kdl

printf '%s\n' 'dendritic-boundaries=PASS'
