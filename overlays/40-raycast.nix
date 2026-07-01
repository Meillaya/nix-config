self: super:
let
  version = "1.104.20";
  sources = {
    aarch64-darwin = super.fetchurl {
      name = "Raycast.dmg";
      url = "https://releases.raycast.com/releases/${version}/download?build=arm";
      hash = "sha256-KUCRNCxCoAetEDXIPBsDcMBnurpBH3GnS0MZ+4rKCfA=";
    };
    x86_64-darwin = super.fetchurl {
      name = "Raycast.dmg";
      url = "https://releases.raycast.com/releases/${version}/download?build=x86_64";
      hash = "sha256-B+VpuvCFLf1nZT4SY3a8XMi8wTyLOeqkM4vd8cSrbEI=";
    };
  };

  updateScript = super.writeShellApplication {
    name = "update-raycast-overlay";
    runtimeInputs = [
      super.curl
      super.git
      super.jq
      super.nix
      super.python3
    ];
    text = ''
      set -euo pipefail

      repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      cd "$repo_root"
      overlay_file="''${RAYCAST_OVERLAY_FILE:-overlays/40-raycast.nix}"
      latest_json="$(curl -fsSL 'https://releases.raycast.com/releases/latest?build=universal')"
      latest_version="$(jq -r '.version' <<<"$latest_json")"

      if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
        echo "Could not determine latest Raycast version" >&2
        exit 1
      fi

      arm_url="https://releases.raycast.com/releases/$latest_version/download?build=arm"
      x86_url="https://releases.raycast.com/releases/$latest_version/download?build=x86_64"
      arm_hash="$(nix store prefetch-file --json --name Raycast.dmg "$arm_url" | jq -r '.hash')"
      x86_hash="$(nix store prefetch-file --json --name Raycast.dmg "$x86_url" | jq -r '.hash')"

      python3 - "$overlay_file" "$latest_version" "$arm_hash" "$x86_hash" <<'PY'
import re
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
version, arm_hash, x86_hash = sys.argv[2:5]
text = path.read_text()

def replace_once(pattern, replacement, label, flags=0):
    global text
    text, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f"Could not update {label}; expected exactly one match, got {count}")

replace_once(r'(version = )"[^"]+";', rf'\g<1>"{version}";', "Raycast version")
replace_once(
    r'(aarch64-darwin = super\.fetchurl \{.*?hash = )"sha256-[^"]+";',
    rf'\g<1>"{arm_hash}";',
    "Raycast aarch64-darwin hash",
    flags=re.S,
)
replace_once(
    r'(x86_64-darwin = super\.fetchurl \{.*?hash = )"sha256-[^"]+";',
    rf'\g<1>"{x86_hash}";',
    "Raycast x86_64-darwin hash",
    flags=re.S,
)
with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tmp:
    tmp.write(text)
    tmp_path = Path(tmp.name)
os.replace(tmp_path, path)
PY

      echo "Raycast overlay is pinned to $latest_version"
    '';
  };
in
super.lib.optionalAttrs super.stdenv.hostPlatform.isDarwin {
  raycast = super.raycast.overrideAttrs (_old: {
    inherit version;

    src = sources.${super.stdenv.hostPlatform.system};

    passthru.updateScript = super.lib.getExe updateScript;
  });
}
