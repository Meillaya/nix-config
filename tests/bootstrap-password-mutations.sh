#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
index=$(mktemp -t nix-bootstrap-mutation-index.XXXXXX)
tmp=$(mktemp -d -t nix-bootstrap-mutations.XXXXXX)
trap 'rm -rf "$tmp"; rm -f "$index"' EXIT

# Snapshot tracked working-tree edits without changing the user's real index.
rm -f "$index"
GIT_INDEX_FILE=$index git -C "$repo" read-tree HEAD
GIT_INDEX_FILE=$index git -C "$repo" add -u
tree=$(GIT_INDEX_FILE=$index git -C "$repo" write-tree)

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

deps_check() {
  local root=$1 filter=$2 expr
  expr="let f = builtins.getFlake (toString $root); in import $root/tests/bootstrap-password-config-eval.nix { config = f.nixosConfigurations.x86_64-linux.config; }"
  nix eval --json --impure --expr "$expr" \
    | jq -e "$filter"
}

root=$(materialize ordering)
sed -i 's/system.activationScripts.users.deps = \[ "bootstrapPasswordHash" \];/system.activationScripts.users.deps = [ ];/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure ordering "$root" false deps_check "$root" \
  '(.userDeps | index("bootstrapPasswordHash")) != null'

root=$(materialize consumer-ordering)
sed -i '0,/deps = \[ "users" \];/s//deps = [ ];/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure consumer-ordering "$root" false deps_check "$root" \
  '(.consumerDeps | index("users")) != null'

root=$(materialize shadow-comparison)
sed -i 's/END { exit !installed }/END { exit 0 }/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure shadow-comparison "$root" 'consumer mismatch was accepted' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize directory-owner-name-lookup)
sed -i "0,/stat -c '%u:%g:%a'/s//stat -c '%U:%g:%a'/" \
  "$root/modules/nixos/bootstrap-password.nix"
sed -i '0,/"0:0:700"/s//"root:0:700"/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure directory-owner-name-lookup "$root" \
  'valid-empty-target-nss expected=pass rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize directory-group-name-lookup)
sed -i "0,/stat -c '%u:%g:%a'/s//stat -c '%u:%G:%a'/" \
  "$root/modules/nixos/bootstrap-password.nix"
sed -i '0,/"0:0:700"/s//"0:root:700"/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure directory-group-name-lookup "$root" \
  'valid-empty-target-nss expected=pass rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize file-owner-name-lookup)
sed -i "/hash_file_meta=/s/'%u:%g:%a'/'%U:%g:%a'/" \
  "$root/modules/nixos/bootstrap-password.nix"
sed -i "/test \"\$hash_file_meta\"/s/\"0:0:600\"/\"root:0:600\"/" \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure file-owner-name-lookup "$root" \
  'valid-empty-target-nss expected=pass rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize file-group-name-lookup)
sed -i "/hash_file_meta=/s/'%u:%g:%a'/'%u:%G:%a'/" \
  "$root/modules/nixos/bootstrap-password.nix"
sed -i "/test \"\$hash_file_meta\"/s/\"0:0:600\"/\"0:root:600\"/" \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure file-group-name-lookup "$root" \
  'valid-empty-target-nss expected=pass rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize pre-users-sentinel-owner-name)
sed -i '0,/chown 0:0/s//chown root:root/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure pre-users-sentinel-owner-name "$root" \
  'missing-existing-unlocked-empty-target-nss expected=pass rc=0 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize pre-users-install-owner-name)
sed -i '0,/install -d -o 0/s//install -d -o root/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure pre-users-install-owner-name "$root" \
  'missing-existing-unlocked-empty-target-nss expected=pass rc=1 verdict=FAIL' \
  bash "$root/tests/bootstrap-password-lifecycle.sh"

root=$(materialize pre-users-install-group-name)
sed -i '0,/install -d -o 0 -g 0/s//install -d -o 0 -g root/' \
  "$root/modules/nixos/bootstrap-password.nix"
expect_failure pre-users-install-group-name "$root" \
  'missing-existing-unlocked-empty-target-nss expected=pass rc=1 verdict=FAIL' \
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

root=$(materialize extra-files-ownership)
sed -i '/--chown var\/lib\/nixos-bootstrap 0:0/d' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure extra-files-ownership "$root" \
  'installer did not enforce root ownership for the bootstrap secret' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize destination-substitution)
sed -i '/--no-substitute-on-destination/d' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure destination-substitution "$root" \
  'installer did not enforce local-only closure transfer' \
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

root=$(materialize installer-tty)
sed -i 's/^env -u SSH_AUTH_SOCK \\/setsid env -u SSH_AUTH_SOCK \\/' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure installer-tty "$root" 'installer detached from caller session' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize installer-agent)
sed -i 's/^env -u SSH_AUTH_SOCK \\/env \\/' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure installer-agent "$root" 'installer inherited SSH agent' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize installer-agent-option)
sed -i '/--ssh-option IdentityAgent=none/d' \
  "$root/bin/nixos-anywhere-bootstrap-password.sh"
expect_failure installer-agent-option "$root" \
  'installer did not disable configured SSH agents' \
  bash "$root/tests/bootstrap-password-install-helper.sh"

root=$(materialize secret-detection)
sed -i 's/initialPassword|//' "$root/tests/bootstrap-password-secret-scan.sh"
expect_failure secret-detection "$root" 'fixture multiline-initial was not detected' \
  bash "$root/tests/bootstrap-password-secret-scan.sh"

printf 'mutation-control=PASS tree=%s\n' "$tree"
printf 'cleanup=%s\n' "$tmp"
