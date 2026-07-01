self: super: with super; {

  feather-font = let
    version = "1.0";
    pname = "feather-font";
    updateScript = writeShellApplication {
      name = "update-feather-font-overlay";
      runtimeInputs = [
        curl
        git
        jq
        nix
        python3
      ];
      text = ''
        set -euo pipefail

        repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
        cd "$repo_root"
        overlay_file="''${FEATHER_FONT_OVERLAY_FILE:-overlays/10-feather-font.nix}"

        latest_version="$(curl -fsSL https://api.github.com/repos/dustinlyons/feather-font/tags | jq -r '.[0].name | sub("^v"; "")')"
        if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
          echo "Could not determine latest feather-font tag" >&2
          exit 1
        fi

        url="https://github.com/dustinlyons/feather-font/archive/refs/tags/$latest_version.zip"
        base32_hash="$(nix-prefetch-url --unpack "$url")"
        sri_hash="$(nix hash convert --hash-algo sha256 --to sri "$base32_hash")"

        python3 - "$overlay_file" "$latest_version" "$sri_hash" <<'PY'
import re
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
version, hash_ = sys.argv[2:4]
text = path.read_text()

def replace_once(pattern, replacement, label):
    global text
    text, count = re.subn(pattern, replacement, text, count=1)
    if count != 1:
        raise SystemExit(f"Could not update {label}; expected exactly one match, got {count}")

replace_once(r'(version = )"[^"]+";', rf'\g<1>"{version}";', "feather-font version")
replace_once(r'(sha256 = )"sha256-[^"]+";', rf'\g<1>"{hash_}";', "feather-font hash")

with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tmp:
    tmp.write(text)
    tmp_path = Path(tmp.name)
os.replace(tmp_path, path)
PY

        echo "feather-font overlay is pinned to $latest_version"
      '';
    };
  in stdenv.mkDerivation {
    name = "${pname}-${version}";

    src = fetchzip {
      url = "https://github.com/dustinlyons/feather-font/archive/refs/tags/${version}.zip";
      sha256 = "sha256-Zsz8/qn7XAG6BVp4XdqooEqioFRV7bLH0bQkHZvFbsg=";
    };

    buildInputs = [ unzip ];
    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp $src/feather.ttf $out/share/fonts/truetype/
    '';

    meta = with lib; {
      homepage = "https://www.feathericons.com/";
      description = "Set of font icons from the open source collection Feather Icons";
      license = licenses.mit;
      maintainers = [ maintainers.dlyons ];
      platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
    };

    passthru.updateScript = lib.getExe updateScript;
  };
}
