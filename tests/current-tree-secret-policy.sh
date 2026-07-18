#!/usr/bin/env bash
set -euo pipefail

repo_root=${CURRENT_TREE_SECRET_POLICY_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}
policy_script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")

python3 - "$repo_root" <<'PY'
import errno
import hashlib
import os
import re
import stat
import subprocess
import sys
from pathlib import PurePosixPath

root_path = os.path.abspath(sys.argv[1])


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(2)


def stat_evidence(value: os.stat_result) -> tuple[int, ...]:
    return (
        value.st_dev,
        value.st_ino,
        value.st_mode,
        value.st_nlink,
        value.st_uid,
        value.st_gid,
        value.st_size,
        value.st_mtime_ns,
        value.st_ctime_ns,
    )


def root_evidence(value: os.stat_result) -> tuple[int, ...]:
    return (
        value.st_dev,
        value.st_ino,
        value.st_mode,
        value.st_uid,
        value.st_gid,
    )


try:
    root_lstat = os.stat(root_path, follow_symlinks=False)
    if not stat.S_ISDIR(root_lstat.st_mode) or root_lstat.st_mode & 0o111 == 0:
        fail("current-tree secret policy could not verify repository root")
    root_fd = os.open(
        root_path,
        os.O_RDONLY | os.O_CLOEXEC | os.O_DIRECTORY | os.O_NOFOLLOW,
    )
    if root_evidence(os.fstat(root_fd)) != root_evidence(root_lstat):
        fail("current-tree secret policy repository root changed while opening")
except OSError:
    fail("current-tree secret policy could not verify repository root")


def canonical_paths(raw_paths: bytes) -> frozenset[PurePosixPath]:
    paths: set[PurePosixPath] = set()
    for raw_path in raw_paths.split(b"\0"):
        if not raw_path:
            continue
        try:
            decoded = os.fsdecode(raw_path)
        except UnicodeError:
            fail("current-tree secret policy encountered an undecodable production path")
        relative = PurePosixPath(decoded)
        if (
            relative.is_absolute()
            or not relative.parts
            or ".." in relative.parts
            or relative.as_posix() != decoded
        ):
            fail("current-tree secret policy encountered an unsafe production path")
        paths.add(relative)
    return frozenset(paths)


def git_output(*arguments: str) -> bytes:
    try:
        result = subprocess.run(
            ["git", *arguments],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            pass_fds=(root_fd,),
            preexec_fn=lambda: os.fchdir(root_fd),
        )
    except (OSError, subprocess.SubprocessError):
        fail("current-tree secret policy could not enumerate production files")
    return result.stdout


if git_output("rev-parse", "--is-inside-work-tree") != b"true\n":
    fail("current-tree secret policy could not verify repository root")
if git_output("rev-parse", "--show-prefix").rstrip(b"\n"):
    fail("current-tree secret policy root is not the repository top level")


def git_paths(*arguments: str) -> frozenset[PurePosixPath]:
    return canonical_paths(git_output("ls-files", *arguments, "-z"))


def enumerate_tree() -> tuple[frozenset[PurePosixPath], frozenset[PurePosixPath]]:
    return (
        git_paths("--cached", "--others", "--exclude-standard"),
        git_paths("--deleted"),
    )


def run_test_hook(phase: str) -> None:
    hook = os.environ.get("CURRENT_TREE_SECRET_POLICY_TEST_HOOK")
    if not hook:
        return
    try:
        subprocess.run(
            [hook, phase, root_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        fail("current-tree secret policy test hook failed")


candidates, intentional_deletions = enumerate_tree()
run_test_hook("after-enumeration")


def excluded(path: PurePosixPath) -> bool:
    parts = path.parts
    return (
        parts[0] in {".omo", ".omx", "docs", "tests"}
        or any(part.lower() in {"fixture", "fixtures", "testdata"} for part in parts)
    )


def credential_config(path: PurePosixPath) -> bool:
    name = path.name.lower()
    suffix = path.suffix.lower()
    return (
        suffix in {".json", ".toml", ".conf", ".cfg", ".ini"}
        or name in {"config", ".env"}
        or name.endswith("config")
    )


assignment = re.compile(
    r'''(?mx)
    ^\s*["']?([A-Za-z][A-Za-z0-9_.-]*)["']?\s*[:=]\s*
    ("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|[^\s,;#}]+)
    ''',
)

sensitive_fields = {
    "apikey": "credential-field:api-key",
    "accesstoken": "credential-field:access-token",
    "authtoken": "credential-field:auth-token",
    "bearertoken": "credential-field:bearer-token",
    "clientsecret": "credential-field:client-secret",
    "credential": "credential-field:credential",
    "password": "credential-field:password",
    "passwd": "credential-field:password",
    "privatekey": "credential-field:private-key",
    "refreshtoken": "credential-field:refresh-token",
    "secretkey": "credential-field:secret-key",
    "token": "credential-field:token",
}

sensitive_suffixes = (
    ("apikey", "credential-field:api-key"),
    ("accesstoken", "credential-field:access-token"),
    ("authtoken", "credential-field:auth-token"),
    ("clientsecret", "credential-field:client-secret"),
    ("password", "credential-field:password"),
    ("privatekey", "credential-field:private-key"),
    ("refreshtoken", "credential-field:refresh-token"),
    ("secretkey", "credential-field:secret-key"),
)

empty_values = {"", '""', "''", "null", "none", "false"}

markers = (
    ("marker:private-key-pem", re.compile(rb"-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----")),
    ("marker:pgp-private-key", re.compile(rb"-----BEGIN PGP PRIVATE KEY BLOCK-----")),
    ("marker:age-secret-key", re.compile(rb"AGE-SECRET-KEY-1[0-9A-Z]+")),
    ("marker:aws-access-key", re.compile(rb"(?:AKIA|ASIA)[0-9A-Z]{16}")),
    ("marker:github-token", re.compile(rb"gh[oprsu]_[A-Za-z0-9_]{20,}")),
    ("marker:openai-token", re.compile(rb"sk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}")),
    ("marker:slack-token", re.compile(rb"xox[baprs]-[A-Za-z0-9-]{20,}")),
)

home_manager_policy = re.compile(
    rb"builtins[.]pathExists|secrets[ \t]*[+].*(?:kavita|calibre)|"
    rb"(?:kavita|calibre).*[.]source"
)


def read_candidate(
    relative: PurePosixPath,
    *,
    keep_data: bool,
) -> tuple[tuple[tuple[int, ...], bytes], bytes] | None:
    directory_fd = os.dup(root_fd)
    try:
        for component in relative.parts[:-1]:
            next_fd = os.open(
                component,
                os.O_RDONLY | os.O_CLOEXEC | os.O_DIRECTORY | os.O_NOFOLLOW,
                dir_fd=directory_fd,
            )
            os.close(directory_fd)
            directory_fd = next_fd
            directory_stat = os.fstat(directory_fd)
            if (
                not stat.S_ISDIR(directory_stat.st_mode)
                or directory_stat.st_mode & 0o111 == 0
            ):
                fail(
                    f"current-tree secret policy could not safely traverse production file: {relative}"
                )

        descriptor = os.open(
            relative.name,
            os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK,
            dir_fd=directory_fd,
        )
    except FileNotFoundError:
        return None
    except OSError as error:
        if error.errno in {errno.ELOOP, errno.ENOTDIR}:
            fail(f"current-tree secret policy could not safely read production file: {relative}")
        fail(f"current-tree secret policy could not read production file: {relative}")
    finally:
        os.close(directory_fd)

    try:
        opened_stat = os.fstat(descriptor)
        if not stat.S_ISREG(opened_stat.st_mode):
            fail(f"current-tree secret policy encountered a non-regular production file: {relative}")
        if opened_stat.st_mode & 0o444 == 0:
            fail(f"current-tree secret policy could not read production file: {relative}")

        digest = hashlib.sha256()
        chunks: list[bytes] = []
        while True:
            chunk = os.read(descriptor, 1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
            if keep_data:
                chunks.append(chunk)
        completed_stat = os.fstat(descriptor)
    except OSError:
        fail(f"current-tree secret policy could not read production file: {relative}")
    finally:
        os.close(descriptor)

    opened_evidence = stat_evidence(opened_stat)
    if stat_evidence(completed_stat) != opened_evidence:
        fail(f"current-tree secret policy file changed while reading: {relative}")
    return (opened_evidence, digest.digest()), b"".join(chunks)


violations: set[tuple[str, str]] = set()
disappeared: set[PurePosixPath] = set()
candidate_evidence: dict[PurePosixPath, tuple[tuple[int, ...], bytes] | None] = {}
ordered_candidates = sorted(candidates, key=lambda path: os.fsencode(path.as_posix()))

for relative in ordered_candidates:
    result = read_candidate(relative, keep_data=True)
    if result is None:
        candidate_evidence[relative] = None
        if relative not in intentional_deletions:
            disappeared.add(relative)
        continue
    evidence, data = result
    candidate_evidence[relative] = evidence

    if relative == PurePosixPath("modules/standalone-linux/home-manager.nix"):
        if home_manager_policy.search(data):
            fail(
                "ignored plaintext application secrets must not enter Nix evaluation "
                "or home.file.source"
            )

    if excluded(relative):
        continue

    for rule, pattern in markers:
        if pattern.search(data):
            violations.add((str(relative), rule))

    if not credential_config(relative):
        continue

    text = data.decode("utf-8", errors="replace")
    for match in assignment.finditer(text):
        normalized_key = re.sub(r"[^a-z0-9]", "", match.group(1).lower())
        rule = sensitive_fields.get(normalized_key)
        if rule is None:
            rule = next(
                (candidate for suffix, candidate in sensitive_suffixes if normalized_key.endswith(suffix)),
                None,
            )
        if rule and match.group(2).strip().lower() not in empty_values:
            violations.add((str(relative), rule))

run_test_hook("before-revalidation")
for relative in ordered_candidates:
    result = read_candidate(relative, keep_data=False)
    expected = candidate_evidence[relative]
    if result is None:
        if expected is not None:
            fail(f"current-tree secret policy file changed after initial scan: {relative}")
        continue
    evidence, _ = result
    if expected is None:
        if relative not in disappeared:
            fail(f"current-tree secret policy file changed after initial scan: {relative}")
        continue
    if evidence != expected:
        fail(f"current-tree secret policy file changed after initial scan: {relative}")

run_test_hook("before-reenumeration")
final_candidates, final_intentional_deletions = enumerate_tree()
if candidates != final_candidates or intentional_deletions != final_intentional_deletions:
    fail("current-tree secret policy production file set changed during scan")

if disappeared:
    for relative in sorted(disappeared, key=lambda path: os.fsencode(path.as_posix())):
        print(
            f"current-tree secret policy production file disappeared during scan: {relative}",
            file=sys.stderr,
        )
    raise SystemExit(2)

if violations:
    for path, rule in sorted(violations):
        print(f"secret-policy violation: file={path} rule={rule}", file=sys.stderr)
    raise SystemExit(1)

try:
    final_root_stat = os.stat(root_path, follow_symlinks=False)
except OSError:
    fail("current-tree secret policy repository root changed during scan")
if root_evidence(final_root_stat) != root_evidence(os.fstat(root_fd)):
    fail("current-tree secret policy repository root changed during scan")
os.close(root_fd)

print("current-tree-secret-policy=PASS")
PY

if [[ ${CURRENT_TREE_SECRET_POLICY_SELFTEST:-1} == 1 ]]; then
  policy_tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/current-tree-secret-policy.XXXXXX")
  trap 'rm -rf "$policy_tmpdir"' EXIT
  fixture_root="$policy_tmpdir/repo"
  mkdir -p "$fixture_root/modules/standalone-linux" "$fixture_root/production"
  git -C "$fixture_root" init -q
  printf '%s\n' '# benign fixture' > "$fixture_root/modules/standalone-linux/home-manager.nix"
  git -C "$fixture_root" add modules/standalone-linux/home-manager.nix
  printf '%s\n' 'apiKey = "not-a-real-credential"' \
    > "$fixture_root/production/intentionally-deleted.toml"
  git -C "$fixture_root" add production/intentionally-deleted.toml
  rm -- "$fixture_root/production/intentionally-deleted.toml"

  CURRENT_TREE_SECRET_POLICY_ROOT="$fixture_root" \
    CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
    "$policy_script" >"$policy_tmpdir/deleted.out"
  grep -Fq 'current-tree-secret-policy=PASS' "$policy_tmpdir/deleted.out"

  cat > "$policy_tmpdir/race-hook" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
phase=$1
root=$2
case "${CURRENT_TREE_SECRET_POLICY_TEST_RACE:-}:$phase" in
  cached-restore:after-enumeration|cached-disappear:after-enumeration)
    rm -- "$root/production/cached-race.toml"
    ;;
  cached-restore:before-reenumeration)
    printf '%s\n' 'benign = "restored"' > "$root/production/cached-race.toml"
    ;;
  untracked-restore:after-enumeration|untracked-disappear:after-enumeration)
    rm -- "$root/production/untracked-race.toml"
    ;;
  untracked-restore:before-reenumeration)
    printf '%s\n' 'benign = "restored"' > "$root/production/untracked-race.toml"
    ;;
  late-content-mutation:before-revalidation)
    printf '%s\n' 'benign = "mutated"' > "$root/production/late-mutation.toml"
    ;;
  parent-symlink-substitution:before-revalidation)
    mv -- "$root/production" "$root/production-original"
    ln -s production-original "$root/production"
    ;;
  enumeration-failure:before-reenumeration)
    mv -- "$root/.git" "$root/.git-hidden"
    ;;
esac
EOF
  chmod 0700 "$policy_tmpdir/race-hook"

  run_race_selftest() {
    local race_kind=$1
    local output=$2
    if CURRENT_TREE_SECRET_POLICY_ROOT="$fixture_root" \
      CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
      CURRENT_TREE_SECRET_POLICY_TEST_HOOK="$policy_tmpdir/race-hook" \
      CURRENT_TREE_SECRET_POLICY_TEST_RACE="$race_kind" \
      "$policy_script" >"$output" 2>&1; then
      printf >&2 'current-tree secret policy accepted a %s race\n' "$race_kind"
      exit 1
    fi
  }

  printf '%s\n' 'benign = "cached"' > "$fixture_root/production/cached-race.toml"
  git -C "$fixture_root" add production/cached-race.toml
  run_race_selftest cached-restore "$policy_tmpdir/cached-restore.out"
  grep -Fq 'production file disappeared during scan: production/cached-race.toml' \
    "$policy_tmpdir/cached-restore.out"

  run_race_selftest cached-disappear "$policy_tmpdir/cached-disappear.out"
  grep -Fq 'production file set changed during scan' "$policy_tmpdir/cached-disappear.out"
  git -C "$fixture_root" rm --cached -q -f production/cached-race.toml

  printf '%s\n' 'benign = "untracked"' > "$fixture_root/production/untracked-race.toml"
  run_race_selftest untracked-restore "$policy_tmpdir/untracked-restore.out"
  grep -Fq 'production file disappeared during scan: production/untracked-race.toml' \
    "$policy_tmpdir/untracked-restore.out"

  run_race_selftest untracked-disappear "$policy_tmpdir/untracked-disappear.out"
  grep -Fq 'production file set changed during scan' "$policy_tmpdir/untracked-disappear.out"

  printf '%s\n' 'benign = "original"' > "$fixture_root/production/late-mutation.toml"
  CURRENT_TREE_SECRET_POLICY_ROOT="$fixture_root" \
    CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
    "$policy_script" >"$policy_tmpdir/unchanged-control.out"
  grep -Fq 'current-tree-secret-policy=PASS' "$policy_tmpdir/unchanged-control.out"

  run_race_selftest late-content-mutation "$policy_tmpdir/late-content-mutation.out"
  grep -Fq 'file changed after initial scan: production/late-mutation.toml' \
    "$policy_tmpdir/late-content-mutation.out"

  run_race_selftest parent-symlink-substitution "$policy_tmpdir/parent-symlink.out"
  grep -Fq 'could not safely read production file: production/' \
    "$policy_tmpdir/parent-symlink.out"
  rm -- "$fixture_root/production"
  mv -- "$fixture_root/production-original" "$fixture_root/production"

  printf '%s\n' 'apiKey = "G016-untracked-production-secret"' \
    > "$fixture_root/production/runtime.toml"

  if CURRENT_TREE_SECRET_POLICY_ROOT="$fixture_root" \
    CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
    "$policy_script" >"$policy_tmpdir/untracked.out" 2>&1; then
    printf >&2 'current-tree secret policy accepted an untracked production secret\n'
    exit 1
  fi
  grep -Fq 'file=production/runtime.toml rule=credential-field:api-key' \
    "$policy_tmpdir/untracked.out"

  rm -- "$fixture_root/production/runtime.toml"
  printf '%s\n' 'benign = "value"' > "$fixture_root/production/unreadable.toml"
  git -C "$fixture_root" add production/unreadable.toml
  chmod 000 "$fixture_root/production/unreadable.toml"
  if CURRENT_TREE_SECRET_POLICY_ROOT="$fixture_root" \
    CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
    "$policy_script" >"$policy_tmpdir/unreadable.out" 2>&1; then
    printf >&2 'current-tree secret policy accepted an unreadable production file\n'
    exit 1
  fi
  chmod 0600 "$fixture_root/production/unreadable.toml"
  grep -Fq 'could not read production file: production/unreadable.toml' \
    "$policy_tmpdir/unreadable.out"

  non_git_root="$policy_tmpdir/non-git"
  mkdir -p "$non_git_root/modules/standalone-linux"
  printf '%s\n' '# benign fixture' > "$non_git_root/modules/standalone-linux/home-manager.nix"
  if CURRENT_TREE_SECRET_POLICY_ROOT="$non_git_root" \
    CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
    "$policy_script" >"$policy_tmpdir/subprocess.out" 2>&1; then
    printf >&2 'current-tree secret policy ignored a Git enumeration failure\n'
    exit 1
  fi
  grep -Fq 'could not enumerate production files' "$policy_tmpdir/subprocess.out"

  printf '%s\n' 'benign = "value"' > "$fixture_root/production/enumeration.toml"
  if CURRENT_TREE_SECRET_POLICY_ROOT="$fixture_root" \
    CURRENT_TREE_SECRET_POLICY_SELFTEST=0 \
    CURRENT_TREE_SECRET_POLICY_TEST_HOOK="$policy_tmpdir/race-hook" \
    CURRENT_TREE_SECRET_POLICY_TEST_RACE=enumeration-failure \
    "$policy_script" >"$policy_tmpdir/reenumeration.out" 2>&1; then
    printf >&2 'current-tree secret policy ignored a Git re-enumeration failure\n'
    exit 1
  fi
  mv -- "$fixture_root/.git-hidden" "$fixture_root/.git"
  grep -Fq 'could not enumerate production files' "$policy_tmpdir/reenumeration.out"
fi
