#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tree=$(git -C "$repo" write-tree)
tmp=$(mktemp -d -t nix-bootstrap-mutations.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

materialize() {
  local name=$1 root="$tmp/$1"
  mkdir -p "$root"
  git -C "$repo" archive "$tree" | tar -x -C "$root"
  git -C "$root" init -q
  git -C "$root" config user.email verifier@example.invalid
  git -C "$root" config user.name verifier
  git -C "$root" add .
  printf '%s\n' "$root"
}

expect_failure() {
  local name=$1 root=$2 expected=$3 rc
  shift 3
  git -C "$root" add .
  set +e
  "$@" > "$tmp/$name.log" 2>&1
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    cat "$tmp/$name.log" >&2
    printf 'mutant-%s=SURVIVED\n' "$name" >&2
    exit 1
  fi
  if ! grep -Fq -- "$expected" "$tmp/$name.log"; then
    cat "$tmp/$name.log" >&2
    printf 'mutant-%s=FAILED-WRONG-REASON expected=%q\n' \
      "$name" "$expected" >&2
    exit 1
  fi
  printf 'mutant-%s=KILLED rc=%s reason=%q\n' "$name" "$rc" "$expected"
}

ordering_check() {
  local root=$1 expr
  expr="let f = builtins.getFlake (toString $root); in import $root/tests/bootstrap-password-config-eval.nix { config = f.nixosConfigurations.x86_64-linux.config; }"
  nix eval --json --impure --expr "$expr" \
    | jq -e '(.userDeps | index("bootstrapPasswordHash")) != null'
}

root=$(materialize ordering)
sed -i 's/system.activationScripts.users.deps = \[ "bootstrapPasswordHash" \];/system.activationScripts.users.deps = [ ];/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure ordering "$root" false ordering_check "$root"

root=$(materialize shadow-comparison)
sed -i 's/END { exit !installed }/END { exit 0 }/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure shadow-comparison "$root" 'consumer mismatch was accepted' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize sentinel-newline)
sed -i "s/printf '!\\\\n'/printf '!'/g" \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure sentinel-newline "$root" \
  'missing-existing-unlocked expected=pass rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize symlink)
sed -i "/test ! -L \"\\\$hash_file\"/d" \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure symlink "$root" 'file-dangling-symlink expected=fail rc=0 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize parent-symlink)
sed -i "/test ! -L \"\\\$hash_dir\"/d" \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure parent-symlink "$root" \
  'parent-symlink expected=fail rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize salt-bound)
sed -i 's/{1,86}/{0,86}/g' \
  "$root/modules/nixos/bootstrap-password.nix" \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure salt-bound "$root" 'empty-salt expected=fail rc=0 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize helper-salt-lower)
sed -i 's/{1,86}/{0,86}/g' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure helper-salt-lower "$root" \
  'generator fixture empty_salt was accepted' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize helper-salt-upper)
sed -i 's/{1,86}/{1,87}/g' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure helper-salt-upper "$root" 'generator salt-87 was accepted' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize extra-files)
sed -i "/--extra-files \"\\\$stage\"/d" \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure extra-files "$root" 'missing extra-files evidence' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize tool-pins)
sed -i \
  -e 's/^nixpkgs_rev=.*/nixpkgs_rev=nixos-unstable/' \
  -e 's/^nixos_anywhere_rev=.*/nixos_anywhere_rev=main/' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure tool-pins "$root" 'unpinned tool reference' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize cleanup)
sed -i "s/rm -rf -- \"\\\$stage\"/:/" \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure cleanup "$root" 'runtime cleanup failed' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize secret-detection)
sed -i 's/initialPassword|//' "$root/tests/bootstrap-password-secret-scan.sh"
expect_failure secret-detection "$root" 'fixture multiline-initial was not detected' \
  bash "$root/tests/bootstrap-password-secret-scan.sh"

printf 'mutation-control=PASS tree=%s\n' "$tree"
printf 'cleanup=%s\n' "$tmp"
