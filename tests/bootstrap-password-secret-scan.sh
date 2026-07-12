#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script=$(readlink -f "${BASH_SOURCE[0]}")

scan_root() (
  set -euo pipefail
  cd "$1"
  local manifest matches='' path output rc
  local hash_pattern
  manifest=$(mktemp -t nix-bootstrap-secret-manifest.XXXXXX)
  trap 'rm -f "$manifest"' EXIT
  git ls-files -z -- hosts modules bin docs flake.nix overlays > "$manifest"
  if [[ -n ${BOOTSTRAP_SECRET_MANIFEST_CAPTURE:-} ]]; then
    cp "$manifest" "$BOOTSTRAP_SECRET_MANIFEST_CAPTURE"
  fi

  while IFS= read -r -d '' path; do
    [[ -r $path ]] || {
      printf 'cannot read tracked production path: %s\n' "$path" >&2
      exit 2
    }
  done < "$manifest"

  while IFS= read -r -d '' path; do
    if [[ $path == *.nix ]]; then
      set +e
      output=$(perl -0777 -ne '
        while (/"?(initialPassword|password|hashedPassword|initialHashedPassword)"?(?:(?:\s+)|(?:\#[^\n]*(?:\n|\z))|(?:\/\*.*?\*\/))*=/sg) {
          print "$ARGV:$1\n";
        }
      ' "$path")
      rc=$?
      set -e
      if (( rc != 0 )); then
        printf 'password-option scan failed: %s\n' "$path" >&2
        exit 2
      fi
      matches+="$output"
    fi

    set +e
    hash_pattern="\\\$(1|2[abxy]?|5|6|7|y|gy|sm3|sm3_yescrypt|gost_yescrypt|scrypt|yescrypt|sha(256|512)crypt|bcrypt|pbkdf2(-sha(256|512))?|argon2(id|i|d))\\\$[./A-Za-z0-9]"
    output=$(grep -InE "$hash_pattern" "$path")
    rc=$?
    set -e
    if (( rc > 1 )); then
      printf 'password-hash scan failed: %s\n' "$path" >&2
      exit 2
    fi
    [[ -z $output ]] || matches+="$path:$output"

    set +e
    output=$(grep -InE \
      'BEGIN ([A-Z0-9]+[[:space:]]+)*PRIVATE KEY|BEGIN PGP PRIVATE KEY BLOCK|AGE-SECRET-KEY-1' \
      "$path")
    rc=$?
    set -e
    if (( rc > 1 )); then
      printf 'private-key scan failed: %s\n' "$path" >&2
      exit 2
    fi
    [[ -z $output ]] || matches+="$path:$output"
  done < "$manifest"

  if [[ -n $matches ]]; then
    printf '%s\n' "$matches"
    exit 1
  fi

  printf '%s\n' \
    'production_plain_or_inline_password_options=0' \
    'production_modular_password_hashes=0' \
    'production_private_key_markers=0'
)

if [[ ${1:-} == --scan-only ]]; then
  scan_root "$2"
  exit
fi

printf '%s\n' 'production-scan-scope=hosts,modules,bin,docs,flake.nix,overlays'

manifest_capture=$(mktemp -t nix-bootstrap-manifest-capture.XXXXXX)
manifest_expected=$(mktemp -t nix-bootstrap-manifest-expected.XXXXXX)
BOOTSTRAP_SECRET_MANIFEST_CAPTURE="$manifest_capture" scan_root "$repo"
git -C "$repo" ls-files -z -- hosts modules bin docs flake.nix overlays \
  > "$manifest_expected"
cmp "$manifest_expected" "$manifest_capture"
rm -f "$manifest_capture" "$manifest_expected"
printf 'production-manifest-complete=PASS\n'

tmp=$(mktemp -d -t nix-bootstrap-secret-scan.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q
git config user.email verifier@example.invalid
git config user.name verifier

run_detected_case() {
  local name=$1 path=$2 content=$3 output rc
  git rm -qrf --ignore-unmatch .
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$content" > "$path"
  git add "$path"
  set +e
  output=$(bash "$script" --scan-only "$tmp" 2>&1)
  rc=$?
  set -e
  if [[ $rc -ne 1 ]]; then
    printf 'fixture %s was not detected\n' "$name" >&2
    exit 1
  fi
  [[ $output == *"$path:"* ]]
  printf '%s-detection=PASS\n' "$name"
}

run_detected_case plaintext modules/config.nix \
  'users.users.mei.password = "fixture-only";'
run_detected_case multiline-initial modules/config.nix \
  'users.users.mei."initialPassword" # legal separator
    = "fixture-only";'
run_detected_case sha512 docs/fixture.txt \
  "\$6\$fixture\$not-a-real-verifier"
run_detected_case bcrypt docs/fixture.txt \
  "\$2b\$12\$fixturefixturefixturefixturefixturefixturefixturefixture"
run_detected_case phc-scrypt docs/fixture.txt \
  "\$scrypt\$ln=16,r=8,p=1\$fixture\$not-a-real-verifier"
run_detected_case private-key docs/fixture.pem \
  '-----BEGIN ENCRYPTED PRIVATE KEY-----'
run_detected_case age-key docs/fixture.txt \
  'AGE-SECRET-KEY-1FIXTUREONLY'

git rm -qrf --ignore-unmatch .
mkdir -p modules bin
cat > modules/config.nix <<'EOF'
users.users.mei.hashedPasswordFile = "/var/lib/nixos-bootstrap/mei-password.hash";
EOF
cat > bin/helper.fish <<'EOF'
set pattern '^\$y\$[./A-Za-z0-9]+\$hash$'
EOF
git add modules/config.nix bin/helper.fish
bash "$script" --scan-only "$tmp" >/dev/null
printf 'external-file-and-regex-negative-control=PASS\n'

chmod 000 modules/config.nix
set +e
output=$(bash "$script" --scan-only "$tmp" 2>&1)
rc=$?
set -e
chmod 600 modules/config.nix
[[ $rc -eq 2 ]]
[[ $output == *'cannot read tracked production path: modules/config.nix'* ]]
printf 'unreadable-file-fails-closed=PASS\n'

mkdir -p mock-bin
cat > mock-bin/perl <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x mock-bin/perl
set +e
output=$(PATH="$PWD/mock-bin:$PATH" bash "$script" --scan-only "$tmp" 2>&1)
rc=$?
set -e
[[ $rc -eq 2 ]]
[[ $output == *'password-option scan failed: modules/config.nix'* ]]
printf 'search-process-error-fails-closed=PASS\n'
rm -rf mock-bin

real_git=$(command -v git)
mkdir -p mock-bin
cat > mock-bin/git <<'EOF'
#!/usr/bin/env sh
if [ "$1" = ls-files ]; then
  exit 2
fi
exec "$REAL_GIT" "$@"
EOF
chmod +x mock-bin/git
set +e
output=$(REAL_GIT="$real_git" PATH="$PWD/mock-bin:$PATH" \
  bash "$script" --scan-only "$tmp" 2>&1)
rc=$?
set -e
[[ $rc -eq 2 ]]
[[ $output != *'production_plain_or_inline_password_options=0'* ]]
printf 'git-file-list-error-fails-closed=PASS\n'
rm -f mock-bin/git

cat > mock-bin/grep <<'EOF'
#!/usr/bin/env sh
exit 2
EOF
chmod +x mock-bin/grep
set +e
output=$(PATH="$PWD/mock-bin:$PATH" bash "$script" --scan-only "$tmp" 2>&1)
rc=$?
set -e
[[ $rc -eq 2 ]]
[[ $output == *'password-hash scan failed:'* ]]
printf 'hash-search-error-fails-closed=PASS\n'

counter="$tmp/grep-counter"
printf '0\n' > "$counter"
cat > mock-bin/grep <<'EOF'
#!/usr/bin/env sh
count=$(cat "$MOCK_GREP_COUNTER")
count=$((count + 1))
printf '%s\n' "$count" > "$MOCK_GREP_COUNTER"
if [ "$count" -eq 1 ]; then
  exit 1
fi
exit 2
EOF
chmod +x mock-bin/grep
set +e
output=$(MOCK_GREP_COUNTER="$counter" PATH="$PWD/mock-bin:$PATH" \
  bash "$script" --scan-only "$tmp" 2>&1)
rc=$?
set -e
[[ $rc -eq 2 ]]
[[ $output == *'private-key scan failed:'* ]]
printf 'private-key-search-error-fails-closed=PASS\n'
rm -rf mock-bin

printf 'cleanup=%s\n' "$tmp"
