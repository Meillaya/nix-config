#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if grep -R -E 'specialArgs|extraSpecialArgs' --include='*.nix' flake.nix modules/flake modules/entities modules/aspects 2>/dev/null; then
  echo 'hidden specialArgs coupling remains in the dendritic graph' >&2
  exit 1
fi

if grep -R -F 'den.batteries.user-shell "nushell"' --include='*.nix' modules 2>/dev/null; then
  echo 'Den user-shell battery cannot configure Nushell OS modules' >&2
  exit 1
fi

if grep -R -E 'command[[:space:]]*=[[:space:]]*/bin/(fish|zsh|bash)' modules/standalone-linux modules/aspects 2>/dev/null; then
  echo 'terminal command bypasses the declarative shell package' >&2
  exit 1
fi

if grep -R -E 'Command=.*pkgs\.(fish|zsh|bash)' --include='*.nix' modules 2>/dev/null; then
  echo 'terminal profile hardcodes a secondary shell' >&2
  exit 1
fi

if test -e hosts/nixos/default.nix || test -e hosts/darwin/default.nix; then
  echo 'legacy host composition entrypoints still exist' >&2
  exit 1
fi

if grep -R -E '^\{[^}]*\buser\b[^}]*\.\.\.' --include='*.nix' modules/aspects/hosts modules/aspects/features 2>/dev/null; then
  echo 'host-scoped class module requests the silently inert Den user argument' >&2
  exit 1
fi

printf '%s\n' 'dendritic-boundaries=PASS'
