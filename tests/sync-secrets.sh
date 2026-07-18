#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

root=${SYNC_SECRETS_TEST_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/sync-secrets.XXXXXX")

cleanup() {
  local status=$?
  trap - EXIT
  if ! chmod -R u+w "$tmpdir" 2>/dev/null; then
    printf >&2 'sync-secrets test cleanup could not make fixtures writable\n'
    status=1
  fi
  if ! rm -rf "$tmpdir"; then
    printf >&2 'sync-secrets test cleanup could not remove fixtures\n'
    status=1
  fi
  exit "$status"
}
trap cleanup EXIT

stub_bin="$tmpdir/bin"
mkdir -p "$stub_bin"
real_mv=$(command -v mv)
export STUB_REAL_MV="$real_mv"

printf '#!%s\n' "$(command -v bash)" > "$stub_bin/git"
cat >> "$stub_bin/git" <<'EOF'
set -euo pipefail

if [[ ${1:-} == clone ]]; then
  if [[ ${STUB_CLONE_FAIL:-0} == 1 ]]; then
    printf >&2 'stub clone failure for %s\n' "$*"
    exit 41
  fi

  destination=${!#}
  mkdir -p "$destination/.git" "$destination/calibre"
  printf '%s\n' 'private-test-material' > "$destination/calibre/gui.py.json"
  printf '%s\n' 'excluded documentation' > "$destination/README.md"
  if [[ ${STUB_CLONE_SOURCE_SYMLINK:-0} == 1 ]]; then
    ln -s "${STUB_SOURCE_SYMLINK_TARGET:?}" "$destination/calibre/linked-secret"
  fi
  exit 0
fi

if [[ ${1:-} == -C && ${3:-} == rev-parse && ${4:-} == --show-toplevel ]]; then
  candidate=$(cd -P -- "$2" && pwd)
  while [[ $candidate != / && ! -d $candidate/.git ]]; do
    candidate=${candidate%/*}
    [[ -n $candidate ]] || candidate=/
  done
  [[ -d $candidate/.git ]] || exit 1
  printf '%s\n' "$candidate"
  exit 0
fi

printf >&2 'unexpected git stub arguments: %s\n' "$*"
exit 97
EOF

printf '#!%s\n' "$(command -v bash)" > "$stub_bin/rsync"
cat >> "$stub_bin/rsync" <<'EOF'
set -euo pipefail
source=${@: -2:1}
destination=${@: -1}

if [[ -n ${STUB_RSYNC_REPLACE_PATH:-} ]]; then
  rm -rf -- "$STUB_RSYNC_REPLACE_PATH"
  mkdir -p -- "$STUB_RSYNC_REPLACE_PATH"
  printf '%s\n' 'replacement' > "$STUB_RSYNC_REPLACE_PATH/replaced-during-rsync"
fi
if [[ -n ${STUB_RSYNC_SYMLINK_PATH:-} ]]; then
  rm -rf -- "$STUB_RSYNC_SYMLINK_PATH"
  ln -s -- "${STUB_RSYNC_SYMLINK_TARGET:?}" "$STUB_RSYNC_SYMLINK_PATH"
fi

mkdir -p "$destination"
cp -R "${source%/}/." "$destination/"
rm -rf -- "$destination/.git" "$destination/README.md"
EOF

printf '#!%s\n' "$(command -v bash)" > "$stub_bin/mv"
cat >> "$stub_bin/mv" <<'EOF'
set -euo pipefail

if [[ ${1:-} == -T && ${2:-} == --exchange && ${3:-} == -- \
  && ${4:-} == .sync-secrets.new.* && ${5:-} == secrets ]]; then
  exchange_count=1
  if [[ -n ${STUB_MV_COUNT_FILE:-} && -f $STUB_MV_COUNT_FILE ]]; then
    read -r exchange_count < "$STUB_MV_COUNT_FILE"
    exchange_count=$((exchange_count + 1))
  fi
  if [[ -n ${STUB_MV_COUNT_FILE:-} ]]; then
    printf '%s\n' "$exchange_count" > "$STUB_MV_COUNT_FILE"
  fi

  if [[ ${STUB_MV_INTERRUPT_BEFORE_EXCHANGE:-0} == 1 && $exchange_count == 1 ]]; then
    kill -TERM "$PPID"
    sleep 0.1
    exit 143
  fi
  if [[ ${STUB_MV_FAIL_EXCHANGE:-0} == 1 && $exchange_count == 1 ]]; then
    exit 42
  fi
  if [[ ${STUB_MV_FAIL_ROLLBACK:-0} == 1 && $exchange_count == 2 ]]; then
    exit 43
  fi

  "${STUB_REAL_MV:?}" "$@"

  if [[ ${STUB_MV_CORRUPT_INSTALLED:-0} == 1 && $exchange_count == 1 ]]; then
    ln -s -- "${STUB_MV_CORRUPT_TARGET:?}" secrets/corrupt-link
  fi
  if [[ ${STUB_MV_INTERRUPT_AFTER_EXCHANGE:-0} == 1 && $exchange_count == 1 ]]; then
    kill -TERM "$PPID"
    sleep 0.1
    exit 0
  fi
  if [[ ${STUB_MV_FAIL_AFTER_EXCHANGE:-0} == 1 && $exchange_count == 1 ]]; then
    exit 44
  fi
  exit 0
fi
exec "${STUB_REAL_MV:?}" "$@"
EOF
chmod +x "$stub_bin/git" "$stub_bin/rsync" "$stub_bin/mv"

make_checkout() {
  local path=$1
  mkdir -p "$path/.git"
  printf '%s\n' '{ outputs = _: { }; }' > "$path/flake.nix"
}

expect_failure() {
  local message=$1
  local output=$2
  shift 2
  if "$@" >"$output" 2>&1; then
    printf >&2 '%s\n' "$message"
    exit 1
  fi
}

expect_interruption_without_absence() {
  local message=$1
  local output=$2
  local checkout=$3
  local absence_marker=$4
  shift 4

  "$@" >"$output" 2>&1 &
  local command_pid=$!
  (
    while kill -0 "$command_pid" 2>/dev/null; do
      if [[ ! -d $checkout/secrets ]]; then
        : > "$absence_marker"
        exit
      fi
    done
  ) &
  local monitor_pid=$!

  local command_status=0
  wait "$command_pid" || command_status=$?
  kill "$monitor_pid" 2>/dev/null || :
  wait "$monitor_pid" 2>/dev/null || :

  if ((command_status == 0)); then
    printf >&2 '%s\n' "$message"
    exit 1
  fi
  if [[ -e $absence_marker ]]; then
    printf >&2 '%s\n' "$message: secrets was absent during interruption handling"
    exit 1
  fi
}

assert_no_stage_tree() {
  local checkout=$1
  local -a stage_trees=("$checkout"/.sync-secrets.new.*)
  if ((${#stage_trees[@]})); then
    printf >&2 'temporary stage tree was not cleaned up: %s\n' "${stage_trees[0]}"
    exit 1
  fi
}

script="$root/apps/linux/sync-secrets"
test -x "$script"

for system in x86_64-linux aarch64-linux; do
  case $system in
    x86_64-linux)
      app_program=${SYNC_SECRETS_APP_PROGRAM_X86_64_LINUX:-}
      ;;
    aarch64-linux)
      app_program=${SYNC_SECRETS_APP_PROGRAM_AARCH64_LINUX:-}
      ;;
  esac
  if [[ -z $app_program ]]; then
    app_program=$(nix eval --impure --raw --expr \
      "(builtins.getFlake \"path:$root\").apps.$system.sync-secrets.program")
  fi
  [[ $app_program == /nix/store/*/bin/sync-secrets ]]

  explicit="$tmpdir/$system-explicit"
  environment_root="$tmpdir/$system-environment"
  make_checkout "$explicit"
  make_checkout "$environment_root"

  PATH="$stub_bin:$PATH" \
    NIX_CONFIG_REPO_ROOT="$environment_root" \
    NIX_SECRETS_REPO=stub://secrets \
    bash "$script" --repo-root "$explicit"

  test -f "$explicit/secrets/calibre/gui.py.json"
  test ! -e "$environment_root/secrets/calibre/gui.py.json"

  PATH="$stub_bin:$PATH" \
    NIX_CONFIG_REPO_ROOT="$environment_root" \
    NIX_SECRETS_REPO=stub://secrets \
    bash "$script"
  test -f "$environment_root/secrets/calibre/gui.py.json"

  detected="$tmpdir/$system-detected"
  make_checkout "$detected"
  expect_failure \
    "$system sync-secrets discovered destination authority from the current directory" \
    "$tmpdir/$system-no-root.out" \
    env -C "$detected" PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      bash "$script"
  grep -Fq -- '--repo-root or NIX_CONFIG_REPO_ROOT' "$tmpdir/$system-no-root.out"
  test ! -e "$detected/secrets"

  expect_failure \
    "$system sync-secrets accepted a Nix store destination" \
    "$tmpdir/$system-store-root.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      bash "$script" --repo-root /nix/store/not-a-checkout
  grep -Fq 'Nix store' "$tmpdir/$system-store-root.out"

  nested_root="$tmpdir/$system-non-root"
  make_checkout "$nested_root"
  mkdir -p "$nested_root/subdirectory"
  expect_failure \
    "$system sync-secrets accepted a checkout subdirectory" \
    "$tmpdir/$system-non-root.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      bash "$script" --repo-root "$nested_root/subdirectory"
  grep -Fq 'checkout root' "$tmpdir/$system-non-root.out"

  unwritable_root="$tmpdir/$system-unwritable"
  make_checkout "$unwritable_root"
  chmod 0555 "$unwritable_root"
  if env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
    bash "$script" --repo-root "$unwritable_root" >"$tmpdir/$system-unwritable.out" 2>&1; then
    chmod 0755 "$unwritable_root"
    echo "$system sync-secrets accepted an unwritable checkout" >&2
    exit 1
  fi
  chmod 0755 "$unwritable_root"
  grep -Fq 'not writable' "$tmpdir/$system-unwritable.out"

  symlink_root="$tmpdir/$system-symlink-root"
  symlink_target="$tmpdir/$system-symlink-root-outside"
  make_checkout "$symlink_root"
  mkdir -p "$symlink_target"
  ln -s "$symlink_target" "$symlink_root/secrets"
  expect_failure \
    "$system sync-secrets followed a symlinked secrets destination" \
    "$tmpdir/$system-symlink-root.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      bash "$script" --repo-root "$symlink_root"
  grep -Fq 'real directory inside the checkout' "$tmpdir/$system-symlink-root.out"
  test ! -e "$symlink_target/calibre/gui.py.json"

  nested_symlink_root="$tmpdir/$system-nested-symlink"
  nested_symlink_target="$tmpdir/$system-nested-symlink-outside"
  make_checkout "$nested_symlink_root"
  mkdir -p "$nested_symlink_root/secrets/application" "$nested_symlink_target"
  ln -s "$nested_symlink_target" "$nested_symlink_root/secrets/application/credentials"
  expect_failure \
    "$system sync-secrets accepted a nested destination symlink" \
    "$tmpdir/$system-nested-symlink.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      bash "$script" --repo-root "$nested_symlink_root"
  grep -Fq 'symlink' "$tmpdir/$system-nested-symlink.out"
  test ! -e "$nested_symlink_target/gui.py.json"

  source_symlink_root="$tmpdir/$system-source-symlink"
  source_symlink_target="$tmpdir/$system-source-symlink-target"
  make_checkout "$source_symlink_root"
  printf '%s\n' 'outside-source-material' > "$source_symlink_target"
  expect_failure \
    "$system sync-secrets accepted a source payload symlink" \
    "$tmpdir/$system-source-symlink.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_CLONE_SOURCE_SYMLINK=1 STUB_SOURCE_SYMLINK_TARGET="$source_symlink_target" \
      bash "$script" --repo-root "$source_symlink_root"
  grep -Fq 'symlink' "$tmpdir/$system-source-symlink.out"
  test ! -e "$source_symlink_root/secrets/calibre/gui.py.json"

  replacement_root="$tmpdir/$system-replacement"
  make_checkout "$replacement_root"
  mkdir -p "$replacement_root/secrets"
  printf '%s\n' 'original' > "$replacement_root/secrets/original"
  expect_failure \
    "$system sync-secrets missed destination replacement during rsync" \
    "$tmpdir/$system-replacement.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_RSYNC_REPLACE_PATH="$replacement_root/secrets" \
      bash "$script" --repo-root "$replacement_root"
  grep -Fq 'changed during synchronization' "$tmpdir/$system-replacement.out"
  test -f "$replacement_root/secrets/replaced-during-rsync"
  test ! -e "$replacement_root/secrets/calibre/gui.py.json"

  symlink_race_root="$tmpdir/$system-symlink-race"
  symlink_race_outside="$tmpdir/$system-symlink-race-outside"
  make_checkout "$symlink_race_root"
  mkdir -p "$symlink_race_root/secrets" "$symlink_race_outside"
  expect_failure \
    "$system sync-secrets missed a destination symlink replacement during rsync" \
    "$tmpdir/$system-symlink-race.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_RSYNC_SYMLINK_PATH="$symlink_race_root/secrets" \
      STUB_RSYNC_SYMLINK_TARGET="$symlink_race_outside" \
      bash "$script" --repo-root "$symlink_race_root"
  grep -Fq 'symlink' "$tmpdir/$system-symlink-race.out"
  test ! -e "$symlink_race_outside/calibre/gui.py.json"

  failed_exchange_root="$tmpdir/$system-failed-exchange"
  make_checkout "$failed_exchange_root"
  mkdir -p "$failed_exchange_root/secrets"
  printf '%s\n' 'original' > "$failed_exchange_root/secrets/original"
  expect_failure \
    "$system sync-secrets did not fail when the atomic exchange failed" \
    "$tmpdir/$system-failed-exchange.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_MV_FAIL_EXCHANGE=1 STUB_REAL_MV="$real_mv" \
      bash "$script" --repo-root "$failed_exchange_root"
  grep -Fq 'could not atomically exchange' "$tmpdir/$system-failed-exchange.out"
  grep -Fxq 'original' "$failed_exchange_root/secrets/original"
  test ! -e "$failed_exchange_root/secrets/calibre/gui.py.json"
  assert_no_stage_tree "$failed_exchange_root"

  failed_after_exchange_root="$tmpdir/$system-failed-after-exchange"
  failed_after_exchange_count="$tmpdir/$system-failed-after-exchange.count"
  make_checkout "$failed_after_exchange_root"
  mkdir -p "$failed_after_exchange_root/secrets"
  printf '%s\n' 'original' > "$failed_after_exchange_root/secrets/original"
  expect_failure \
    "$system sync-secrets did not roll back an exchange reported as failed" \
    "$tmpdir/$system-failed-after-exchange.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_MV_FAIL_AFTER_EXCHANGE=1 \
      STUB_MV_COUNT_FILE="$failed_after_exchange_count" STUB_REAL_MV="$real_mv" \
      bash "$script" --repo-root "$failed_after_exchange_root"
  grep -Fq 'could not atomically exchange' "$tmpdir/$system-failed-after-exchange.out"
  grep -Fxq '2' "$failed_after_exchange_count"
  grep -Fxq 'original' "$failed_after_exchange_root/secrets/original"
  test ! -e "$failed_after_exchange_root/secrets/calibre/gui.py.json"
  assert_no_stage_tree "$failed_after_exchange_root"

  validation_rollback_root="$tmpdir/$system-validation-rollback"
  validation_rollback_count="$tmpdir/$system-validation-rollback.count"
  validation_corrupt_target="$tmpdir/$system-validation-corrupt-target"
  make_checkout "$validation_rollback_root"
  mkdir -p "$validation_rollback_root/secrets"
  printf '%s\n' 'original' > "$validation_rollback_root/secrets/original"
  : > "$validation_corrupt_target"
  expect_failure \
    "$system sync-secrets did not roll back failed post-exchange validation" \
    "$tmpdir/$system-validation-rollback.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_MV_CORRUPT_INSTALLED=1 STUB_MV_CORRUPT_TARGET="$validation_corrupt_target" \
      STUB_MV_COUNT_FILE="$validation_rollback_count" STUB_REAL_MV="$real_mv" \
      bash "$script" --repo-root "$validation_rollback_root"
  grep -Fq 'installed secrets payload must not contain symlinks' \
    "$tmpdir/$system-validation-rollback.out"
  grep -Fxq '2' "$validation_rollback_count"
  grep -Fxq 'original' "$validation_rollback_root/secrets/original"
  test ! -e "$validation_rollback_root/secrets/calibre/gui.py.json"
  assert_no_stage_tree "$validation_rollback_root"

  pre_interrupt_root="$tmpdir/$system-pre-interrupt"
  pre_interrupt_count="$tmpdir/$system-pre-interrupt.count"
  make_checkout "$pre_interrupt_root"
  mkdir -p "$pre_interrupt_root/secrets"
  printf '%s\n' 'original' > "$pre_interrupt_root/secrets/original"
  expect_interruption_without_absence \
    "$system sync-secrets survived a pre-exchange interruption" \
    "$tmpdir/$system-pre-interrupt.out" "$pre_interrupt_root" \
    "$tmpdir/$system-pre-interrupt.absent" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_MV_INTERRUPT_BEFORE_EXCHANGE=1 \
      STUB_MV_COUNT_FILE="$pre_interrupt_count" STUB_REAL_MV="$real_mv" \
      bash "$script" --repo-root "$pre_interrupt_root"
  grep -Fq 'interrupted by TERM' "$tmpdir/$system-pre-interrupt.out"
  grep -Fxq '1' "$pre_interrupt_count"
  grep -Fxq 'original' "$pre_interrupt_root/secrets/original"
  test ! -e "$pre_interrupt_root/secrets/calibre/gui.py.json"
  assert_no_stage_tree "$pre_interrupt_root"

  post_interrupt_root="$tmpdir/$system-post-interrupt"
  post_interrupt_count="$tmpdir/$system-post-interrupt.count"
  make_checkout "$post_interrupt_root"
  mkdir -p "$post_interrupt_root/secrets"
  printf '%s\n' 'original' > "$post_interrupt_root/secrets/original"
  expect_interruption_without_absence \
    "$system sync-secrets survived a post-exchange interruption" \
    "$tmpdir/$system-post-interrupt.out" "$post_interrupt_root" \
    "$tmpdir/$system-post-interrupt.absent" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_MV_INTERRUPT_AFTER_EXCHANGE=1 \
      STUB_MV_COUNT_FILE="$post_interrupt_count" STUB_REAL_MV="$real_mv" \
      bash "$script" --repo-root "$post_interrupt_root"
  grep -Fq 'interrupted by TERM' "$tmpdir/$system-post-interrupt.out"
  grep -Fxq '2' "$post_interrupt_count"
  grep -Fxq 'original' "$post_interrupt_root/secrets/original"
  test ! -e "$post_interrupt_root/secrets/calibre/gui.py.json"
  assert_no_stage_tree "$post_interrupt_root"

  rollback_failure_root="$tmpdir/$system-rollback-failure"
  rollback_failure_count="$tmpdir/$system-rollback-failure.count"
  rollback_failure_target="$tmpdir/$system-rollback-failure-target"
  make_checkout "$rollback_failure_root"
  mkdir -p "$rollback_failure_root/secrets"
  printf '%s\n' 'original' > "$rollback_failure_root/secrets/original"
  : > "$rollback_failure_target"
  expect_failure \
    "$system sync-secrets hid a failed atomic rollback" \
    "$tmpdir/$system-rollback-failure.out" \
    env PATH="$stub_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
      STUB_MV_CORRUPT_INSTALLED=1 STUB_MV_CORRUPT_TARGET="$rollback_failure_target" \
      STUB_MV_FAIL_ROLLBACK=1 STUB_MV_COUNT_FILE="$rollback_failure_count" \
      STUB_REAL_MV="$real_mv" \
      bash "$script" --repo-root "$rollback_failure_root"
  grep -Fq 'atomic rollback failed; preserved both live and displaced trees' \
    "$tmpdir/$system-rollback-failure.out"
  grep -Fxq '2' "$rollback_failure_count"
  test -d "$rollback_failure_root/secrets"
  test -f "$rollback_failure_root/secrets/calibre/gui.py.json"
  rollback_failure_stages=("$rollback_failure_root"/.sync-secrets.new.*)
  ((${#rollback_failure_stages[@]} == 1))
  grep -Fxq 'original' "${rollback_failure_stages[0]}/original"

  credential_root="$tmpdir/$system-credential-log"
  credential_sentinel="G016-CREDENTIAL-SENTINEL-$system"
  make_checkout "$credential_root"
  expect_failure \
    "$system sync-secrets accepted a failed clone" \
    "$tmpdir/$system-credential-log.out" \
    env PATH="$stub_bin:$PATH" STUB_CLONE_FAIL=1 \
      bash "$script" --repo "https://user:$credential_sentinel@example.invalid/secrets.git" \
      --repo-root "$credential_root"
  grep -Fq 'failed to clone configured secrets repository' "$tmpdir/$system-credential-log.out"
  if grep -Fq "$credential_sentinel" "$tmpdir/$system-credential-log.out"; then
    echo "$system sync-secrets logged raw repository credentials" >&2
    exit 1
  fi
done

# Run one end-to-end replacement with no mv stub in PATH. This exercises the
# host GNU coreutils implementation of mv --exchange rather than merely checking
# stub arguments while still keeping clone and rsync fixtures deterministic.
real_mv_bin="$tmpdir/real-mv-bin"
mkdir -p "$real_mv_bin"
cp -- "$stub_bin/git" "$stub_bin/rsync" "$real_mv_bin/"
chmod +x "$real_mv_bin/git" "$real_mv_bin/rsync"
real_exchange_root="$tmpdir/real-coreutils-exchange"
make_checkout "$real_exchange_root"
mkdir -p "$real_exchange_root/secrets"
printf '%s\n' 'original' > "$real_exchange_root/secrets/original"
PATH="$real_mv_bin:$PATH" NIX_SECRETS_REPO=stub://secrets \
  bash "$script" --repo-root "$real_exchange_root"
test -d "$real_exchange_root/secrets"
test -f "$real_exchange_root/secrets/calibre/gui.py.json"
test ! -e "$real_exchange_root/secrets/original"
[[ $(stat -Lc '%a' -- "$real_exchange_root/secrets") == 700 ]]
assert_no_stage_tree "$real_exchange_root"

if grep -Fq 'NIX_CONFIG_REPO_ROOT = toString self' "$root/modules/flake/apps.nix"; then
  echo 'sync-secrets wrapper still injects the immutable flake source as repo root' >&2
  exit 1
fi

printf '%s\n' 'sync-secrets=PASS'
