#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
flake="path:$root"

eval_bin() {
  local package=$1
  nix build --impure --no-link --expr \
    "let f = builtins.getFlake \"$flake\"; in f.nixosConfigurations.\"x86_64-linux\".pkgs.$package" \
    >/dev/null
  nix eval --impure --raw --expr \
    "let f = builtins.getFlake \"$flake\"; in \"\${f.nixosConfigurations.\"x86_64-linux\".pkgs.$package}/bin/$2\""
}

nu=$(eval_bin nushell nu)
bash_bin=$(eval_bin bashInteractive bash)
zsh=$(eval_bin zsh zsh)
fish=$(eval_bin fish fish)

test "$($nu -c 'print nu-ok')" = nu-ok
test "$($bash_bin -c 'printf bash-ok')" = bash-ok
test "$($zsh -fc 'printf zsh-ok')" = zsh-ok
test "$($fish -c 'printf fish-ok')" = fish-ok

printf '%s\n' 'dendritic-shells=PASS'
