#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
helper="$repo/bin/nixos-anywhere-bootstrap-password.fish"
tmp=$(mktemp -d -t nix-bootstrap-password-helper.XXXXXX)
trap 'rm -rf "$tmp"' EXIT

[[ -x $helper ]]
fish --no-execute "$helper"

mkdir -p "$tmp/bin" "$tmp/runtime"
cat > "$tmp/bin/findmnt" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "${MOCK_FSTYPE:-tmpfs}"
EOF
cat > "$tmp/bin/nix" <<'EOF'
#!/usr/bin/env sh
case "$1" in
  shell)
    printf 'mkpasswd_ref=%s\n' "$2" >> "$MOCK_CAPTURE"
    if [ "${MOCK_GENERATOR_FAIL:-0}" = 1 ]; then
      exit 7
    elif [ "${MOCK_MULTILINE:-0}" = 1 ]; then
      printf '%s\n%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' extra
    elif [ "${MOCK_NO_FINAL_NEWLINE:-0}" = 1 ]; then
      printf '%s' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
    elif [ "${MOCK_UNTERMINATED_TRAILING:-0}" = 1 ]; then
      printf '%s\n%s' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012' extra
    elif [ "${MOCK_EMPTY_SALT:-0}" = 1 ]; then
      printf '%s\n' '$y$j9T$$0123456789012345678901234567890123456789012'
    elif [ -n "${MOCK_SALT_LENGTH:-}" ]; then
      salt=$(printf '%*s' "$MOCK_SALT_LENGTH" '' | tr ' ' a)
      printf '$y$j9T$%s$%s\n' "$salt" \
        '0123456789012345678901234567890123456789012'
    else
      printf '%s\n' '$y$j9T$abcdefghijklmnop$0123456789012345678901234567890123456789012'
    fi
    ;;
  run)
    printf 'nixos_anywhere_ref=%s\n' "$2" >> "$MOCK_CAPTURE"
    shift
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --target-host)
          printf 'target=%s\n' "$2" >> "$MOCK_CAPTURE"
          shift 2
          ;;
        --flake)
          printf 'flake=%s\n' "$2" >> "$MOCK_CAPTURE"
          shift 2
          ;;
        --extra-files)
          stage=$2
          hash="$stage/var/lib/nixos-bootstrap/mei-password.hash"
          printf 'extra_files=%s\n' "$stage" >> "$MOCK_CAPTURE"
          printf 'stage_mode=%s\n' "$(stat -c %a "$stage")" >> "$MOCK_CAPTURE"
          printf 'hash_mode=%s\n' "$(stat -c %a "$hash")" >> "$MOCK_CAPTURE"
          printf 'dir_mode=%s\n' "$(stat -c %a "$stage/var/lib/nixos-bootstrap")" >> "$MOCK_CAPTURE"
          grep -Eqx '^\$y\$[./A-Za-z0-9]+\$[./A-Za-z0-9]{1,86}\$[./A-Za-z0-9]{43}$' "$hash"
          shift 2
          ;;
        *) shift ;;
      esac
    done
    if [ "${MOCK_INSTALLER_SLEEP:-0}" = 1 ]; then
      printf 'installer_started=1\n' >> "$MOCK_CAPTURE"
      sleep 300 &
      child=$!
      printf 'child_pid=%s\n' "$child" >> "$MOCK_CAPTURE"
      wait "$child"
    fi
    exit "${MOCK_INSTALLER_RC:-0}"
    ;;
  *) exit 9 ;;
esac
EOF
chmod +x "$tmp/bin/findmnt" "$tmp/bin/nix"

run_env=(env \
  PATH="$tmp/bin:$PATH" \
  XDG_RUNTIME_DIR="$tmp/runtime" \
  MOCK_CAPTURE="$tmp/capture")

assert_runtime_empty() {
  if find "$tmp/runtime" -mindepth 1 -maxdepth 1 -print -quit \
    | grep -q .; then
    printf 'runtime cleanup failed\n' >&2
    return 1
  fi
}

"${run_env[@]}" "$helper" root@mock-target .#x86_64-linux
grep -qx 'target=root@mock-target' "$tmp/capture"
grep -qx 'flake=.#x86_64-linux' "$tmp/capture"
if ! grep -Eq \
  '^mkpasswd_ref=github:NixOS/nixpkgs/[0-9a-f]{40}#mkpasswd$' \
  "$tmp/capture" \
  || ! grep -Eq \
    '^nixos_anywhere_ref=github:nix-community/nixos-anywhere/[0-9a-f]{40}$' \
    "$tmp/capture"; then
  printf 'unpinned tool reference\n' >&2
  exit 1
fi
grep -q '^extra_files=' "$tmp/capture" || {
  printf 'missing extra-files evidence\n' >&2
  exit 1
}
grep -qx 'stage_mode=700' "$tmp/capture"
grep -qx 'hash_mode=600' "$tmp/capture" || {
  printf 'missing extra-files evidence\n' >&2
  exit 1
}
grep -qx 'dir_mode=700' "$tmp/capture"
assert_runtime_empty
printf 'success-and-cleanup=PASS\n'

: > "$tmp/capture"
"${run_env[@]}" "$helper" root@mock-target
grep -qx 'flake=.#x86_64-linux' "$tmp/capture"
assert_runtime_empty
printf 'default-flake=PASS\n'

for args in zero three; do
  set +e
  if [[ $args == zero ]]; then
    "${run_env[@]}" "$helper"
  else
    "${run_env[@]}" "$helper" one two three
  fi
  rc=$?
  set -e
  [[ $rc -eq 2 ]]
  assert_runtime_empty
  printf 'argument-count-%s=PASS rc=%s\n' "$args" "$rc"
done

set +e
env -u XDG_RUNTIME_DIR PATH="$tmp/bin:$PATH" MOCK_CAPTURE="$tmp/capture" \
  "$helper" root@mock-target
rc=$?
set -e
[[ $rc -eq 1 ]]
assert_runtime_empty
printf 'unset-runtime=PASS rc=%s\n' "$rc"

set +e
MOCK_FSTYPE=ext4 "${run_env[@]}" "$helper" root@mock-target
rc=$?
set -e
[[ $rc -eq 1 ]]
assert_runtime_empty
printf 'non-tmpfs-runtime=PASS rc=%s\n' "$rc"

for mode in GENERATOR_FAIL MULTILINE NO_FINAL_NEWLINE UNTERMINATED_TRAILING EMPTY_SALT; do
  set +e
  env_name="MOCK_$mode"
  env "$env_name=1" "${run_env[@]}" \
    "$helper" root@mock-target .#x86_64-linux
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    printf 'generator fixture %s was accepted\n' "${mode,,}" >&2
    exit 1
  fi
  assert_runtime_empty
  printf '%s-rejected-and-cleaned=PASS rc=%s\n' "${mode,,}" "$rc"
done

for salt_length in 1 86 87; do
  : > "$tmp/capture"
  set +e
  MOCK_SALT_LENGTH=$salt_length "${run_env[@]}" \
    "$helper" root@mock-target .#x86_64-linux
  rc=$?
  set -e
  if [[ $salt_length -le 86 && $rc -ne 0 ]]; then
    printf 'generator salt-%s was rejected\n' "$salt_length" >&2
    exit 1
  fi
  if [[ $salt_length -eq 87 && $rc -eq 0 ]]; then
    printf 'generator salt-87 was accepted\n' >&2
    exit 1
  fi
  assert_runtime_empty
  printf 'generator-salt-%s-boundary=PASS rc=%s\n' "$salt_length" "$rc"
done

set +e
MOCK_INSTALLER_RC=42 "${run_env[@]}" \
  "$helper" root@mock-target .#x86_64-linux
rc=$?
set -e
[[ $rc -eq 42 ]]
assert_runtime_empty
printf 'installer-failure-status-and-cleanup=PASS rc=%s\n' "$rc"

run_signal_case() {
  local signal=$1 expected=$2 pid rc child_pid
  : > "$tmp/capture"
  MOCK_INSTALLER_SLEEP=1 setsid "${run_env[@]}" \
    "$helper" root@mock-target .#x86_64-linux &
  pid=$!
  for _ in $(seq 1 100); do
    grep -qx 'installer_started=1' "$tmp/capture" 2>/dev/null && break
    sleep 0.05
  done
  grep -qx 'installer_started=1' "$tmp/capture"
  child_pid=$(sed -n 's/^child_pid=//p' "$tmp/capture")
  [[ -n $child_pid ]]
  kill -"$signal" "$pid"
  set +e
  wait "$pid"
  rc=$?
  set -e
  [[ $rc -eq $expected ]]
  for _ in $(seq 1 100); do
    kill -0 "$child_pid" 2>/dev/null || break
    sleep 0.01
  done
  if kill -0 "$child_pid" 2>/dev/null; then
    return 1
  fi
  assert_runtime_empty
  printf '%s-status-child-and-cleanup=PASS rc=%s child=%s\n' \
    "${signal,,}" "$rc" "$child_pid"
}

run_signal_case HUP 129
run_signal_case INT 130
run_signal_case TERM 143

printf 'cleanup=%s\n' "$tmp"
