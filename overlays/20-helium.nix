self: super:
let
  inherit (super) lib;

  linuxVersion = "0.11.3.2";
  linuxSources = {
    x86_64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${linuxVersion}/helium-${linuxVersion}-x86_64.AppImage";
      sha256 = "0w1q106i1cvgi0dxmw69dywv0xi6m3kjy4gxlnhmsrbn1lm741z6";
    };
    aarch64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/${linuxVersion}/helium-${linuxVersion}-arm64.AppImage";
      sha256 = "1w5yi80p5djnsbwisb47q44i5yzchql7iffvyy9gi6l5nh3i7mlk";
    };
  };
  system = super.stdenv.hostPlatform.system;

  mkOverlayUpdater = name: text: super.writeShellApplication {
    inherit name text;
    runtimeInputs = [
      super.curl
      super.git
      super.jq
      super.nix
      super.python3
    ];
  };

  updateHeliumScript = mkOverlayUpdater "update-helium-overlay" ''
    set -euo pipefail

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    cd "$repo_root"
    overlay_file="''${HELIUM_OVERLAY_FILE:-overlays/20-helium.nix}"

    linux_version="$(curl -fsSL https://api.github.com/repos/imputnet/helium-linux/releases/latest | jq -r '.tag_name | sub("^v"; "")')"
    darwin_version="$(curl -fsSL https://api.github.com/repos/imputnet/helium-macos/releases/latest | jq -r '.tag_name | sub("^v"; "")')"

    linux_x86_url="https://github.com/imputnet/helium-linux/releases/download/$linux_version/helium-$linux_version-x86_64.AppImage"
    linux_arm_url="https://github.com/imputnet/helium-linux/releases/download/$linux_version/helium-$linux_version-arm64.AppImage"
    darwin_arm_url="https://github.com/imputnet/helium-macos/releases/download/$darwin_version/helium_''${darwin_version}_arm64-macos.dmg"
    darwin_x86_url="https://github.com/imputnet/helium-macos/releases/download/$darwin_version/helium_''${darwin_version}_x86_64-macos.dmg"

    linux_x86_hash="$(nix store prefetch-file --json "$linux_x86_url" | jq -r '.hash')"
    linux_arm_hash="$(nix store prefetch-file --json "$linux_arm_url" | jq -r '.hash')"
    darwin_arm_hash="$(nix store prefetch-file --json "$darwin_arm_url" | jq -r '.hash')"
    darwin_x86_hash="$(nix store prefetch-file --json "$darwin_x86_url" | jq -r '.hash')"

    python3 - "$overlay_file" "$linux_version" "$linux_x86_hash" "$linux_arm_hash" "$darwin_version" "$darwin_arm_hash" "$darwin_x86_hash" <<'PY'
import re
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
linux_version, linux_x86_hash, linux_arm_hash, darwin_version, darwin_arm_hash, darwin_x86_hash = sys.argv[2:8]
text = path.read_text()

def replace_once(pattern, replacement, label, flags=0):
    global text
    text, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f"Could not update {label}; expected exactly one match, got {count}")

replace_once(r'(linuxVersion = )"[^"]+";', rf'\g<1>"{linux_version}";', "Helium Linux version")
replace_once(r'(x86_64-linux = \{.*?sha256 = )"[^"]+";', rf'\g<1>"{linux_x86_hash}";', "Helium x86_64-linux hash", flags=re.S)
replace_once(r'(aarch64-linux = \{.*?sha256 = )"[^"]+";', rf'\g<1>"{linux_arm_hash}";', "Helium aarch64-linux hash", flags=re.S)
replace_once(r'(helium = mkDarwinApp rec \{.*?version = )"[^"]+";', rf'\g<1>"{darwin_version}";', "Helium Darwin version", flags=re.S)
replace_once(
    r'(helium = mkDarwinApp rec \{.*?hash = if .*? then )"sha256-[^"]+"(\s*else )"sha256-[^"]+";',
    rf'\g<1>"{darwin_arm_hash}"\g<2>"{darwin_x86_hash}";',
    "Helium Darwin hashes",
    flags=re.S,
)
with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tmp:
    tmp.write(text)
    tmp_path = Path(tmp.name)
os.replace(tmp_path, path)
PY

    echo "Helium overlay is pinned to Linux $linux_version and macOS $darwin_version"
  '';

  updateOmniWMScript = mkOverlayUpdater "update-omniwm-overlay" ''
    set -euo pipefail

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    cd "$repo_root"
    overlay_file="''${HELIUM_OVERLAY_FILE:-overlays/20-helium.nix}"

    version="$(curl -fsSL https://api.github.com/repos/BarutSRB/OmniWM/releases/latest | jq -r '.tag_name | sub("^v"; "")')"
    url="https://github.com/BarutSRB/OmniWM/releases/download/v$version/OmniWM-v$version.zip"
    hash="$(nix store prefetch-file --json --name "OmniWM-v$version.zip" "$url" | jq -r '.hash')"

    python3 - "$overlay_file" "$version" "$hash" <<'PY'
import re
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
version, hash_ = sys.argv[2:4]
text = path.read_text()

def replace_once(pattern, replacement, label, flags=0):
    global text
    text, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f"Could not update {label}; expected exactly one match, got {count}")

replace_once(r'(omniwm = mkDarwinApp rec \{.*?version = )"[^"]+";', rf'\g<1>"{version}";', "OmniWM version", flags=re.S)
replace_once(r'(omniwm = mkDarwinApp rec \{.*?hash = )"sha256-[^"]+";', rf'\g<1>"{hash_}";', "OmniWM hash", flags=re.S)

with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tmp:
    tmp.write(text)
    tmp_path = Path(tmp.name)
os.replace(tmp_path, path)
PY

    echo "OmniWM overlay is pinned to $version"
  '';

  updateStremioScript = mkOverlayUpdater "update-stremio-overlay" ''
    set -euo pipefail

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    cd "$repo_root"
    overlay_file="''${HELIUM_OVERLAY_FILE:-overlays/20-helium.nix}"
    downloads_html="$(curl -fsSL https://www.stremio.com/downloads)"
    version="$(printf '%s' "$downloads_html" | python3 -c "
import re
import sys
html = sys.stdin.read()
versions = re.findall(r'stremio-shell-macos/v([0-9.]+)/Stremio_arm64\.dmg', html)
if not versions:
    raise SystemExit('could not find Stremio macOS version')
print(sorted(set(versions), key=lambda v: [int(p) for p in v.split('.')])[-1])
    ")"

    arm_url="https://dl.strem.io/stremio-shell-macos/v$version/Stremio_arm64.dmg"
    x86_url="https://dl.strem.io/stremio-shell-macos/v$version/Stremio_x64.dmg"
    arm_hash="$(nix store prefetch-file --json --name Stremio_arm64.dmg "$arm_url" | jq -r '.hash')"
    x86_hash="$(nix store prefetch-file --json --name Stremio_x64.dmg "$x86_url" | jq -r '.hash')"

    python3 - "$overlay_file" "$version" "$arm_hash" "$x86_hash" <<'PY'
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

replace_once(r'(stremio = mkDarwinApp rec \{.*?version = )"[^"]+";', rf'\g<1>"{version}";', "Stremio version", flags=re.S)
replace_once(
    r'(stremio = mkDarwinApp rec \{.*?hash = if .*? then )"sha256-[^"]+"(\s*else )"sha256-[^"]+";',
    rf'\g<1>"{arm_hash}"\g<2>"{x86_hash}";',
    "Stremio hashes",
    flags=re.S,
)
with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tmp:
    tmp.write(text)
    tmp_path = Path(tmp.name)
os.replace(tmp_path, path)
PY

    echo "Stremio overlay is pinned to $version"
  '';

  updateSublimeTextScript = mkOverlayUpdater "update-sublime-text-overlay" ''
    set -euo pipefail

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    cd "$repo_root"
    overlay_file="''${HELIUM_OVERLAY_FILE:-overlays/20-helium.nix}"
    download_html="$(curl -fsSL https://www.sublimetext.com/download)"
    version="$(printf '%s' "$download_html" | python3 -c "
import re
import sys
html = sys.stdin.read()
builds = [int(build) for build in re.findall(r'Build ([0-9]+)', html)]
if not builds:
    raise SystemExit('could not find Sublime Text build')
print(max(builds))
    ")"

    url="https://download.sublimetext.com/sublime_text_build_''${version}_mac.zip"
    hash="$(nix store prefetch-file --json --name "sublime_text_build_''${version}_mac.zip" "$url" | jq -r '.hash')"

    python3 - "$overlay_file" "$version" "$hash" <<'PY'
import re
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
version, hash_ = sys.argv[2:4]
text = path.read_text()

def replace_once(pattern, replacement, label, flags=0):
    global text
    text, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f"Could not update {label}; expected exactly one match, got {count}")

replace_once(r'(sublimeText = mkDarwinApp rec \{.*?version = )"[^"]+";', rf'\g<1>"{version}";', "Sublime Text version", flags=re.S)
replace_once(r'(sublimeText = mkDarwinApp rec \{.*?hash = )"sha256-[^"]+";', rf'\g<1>"{hash_}";', "Sublime Text hash", flags=re.S)

with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tmp:
    tmp.write(text)
    tmp_path = Path(tmp.name)
os.replace(tmp_path, path)
PY

    echo "Sublime Text overlay is pinned to build $version"
  '';

  mkDarwinApp =
    { pname
    , version
    , url
    , hash
    , appName
    , description
    , homepage
    , nativeBuildInputs
    , license ? lib.licenses.unfreeRedistributable
    , extraInstall ? ""
    , updateScript ? null
    }:
    super.stdenvNoCC.mkDerivation {
      inherit pname version;

      src = super.fetchurl { inherit url hash; };
      inherit nativeBuildInputs;
      sourceRoot = ".";

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        app_bundle="$(find . -name "${appName}.app" -type d -prune | head -n 1)"
        if [ -z "$app_bundle" ]; then
          echo "could not find ${appName}.app in unpacked archive" >&2
          find . -maxdepth 3 -print >&2
          exit 1
        fi

        mkdir -p "$out/Applications"
        cp -R "$app_bundle" "$out/Applications/"
        ${extraInstall}

        runHook postInstall
      '';

      meta = with lib; {
        inherit description homepage license;
        platforms = platforms.darwin;
        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      };

      passthru = lib.optionalAttrs (updateScript != null) {
        updateScript = lib.getExe updateScript;
      };
    };

  linuxAttrs =
    let source = linuxSources.${system} or null;
    in lib.optionalAttrs (source != null) {
      helium = super.appimageTools.wrapType2 rec {
        pname = "helium";
        version = linuxVersion;

        src = super.fetchurl source;

        extraInstallCommands = ''
          if [ -f "$out/share/applications/helium.desktop" ]; then
            substituteInPlace "$out/share/applications/helium.desktop" \
              --replace-fail 'Exec=AppRun' 'Exec=helium'
          fi
        '';

        meta = with lib; {
          description = "Private, fast, and honest web browser";
          homepage = "https://github.com/imputnet/helium-linux";
          downloadPage = "https://github.com/imputnet/helium-linux/releases";
          license = [ licenses.gpl3Only licenses.bsd3 ];
          platforms = builtins.attrNames linuxSources;
          sourceProvenance = with sourceTypes; [ binaryNativeCode ];
          mainProgram = "helium";
        };

        passthru.updateScript = lib.getExe updateHeliumScript;
      };
    };

  darwinAttrs = lib.optionalAttrs super.stdenv.hostPlatform.isDarwin rec {
    helium = mkDarwinApp rec {
      pname = "helium";
      version = "0.11.5.1";
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_${if super.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64"}-macos.dmg";
      hash = if super.stdenv.hostPlatform.isAarch64
        then "sha256-P5iXtXS05uu5Qy9jPheXAbjewn6jKTcqc5uF2yZoz/k="
        else "sha256-YI0c5DDtPizr/muDCi8bWu3wU96WDxw6y8bmCOb6sw0=";
      appName = "Helium";
      description = "Chromium-based web browser";
      homepage = "https://helium.computer/";
      nativeBuildInputs = [ super._7zz ];
      updateScript = updateHeliumScript;
    };

    helium-browser = helium;

    omniwm = mkDarwinApp rec {
      pname = "omniwm";
      version = "0.5.2.1";
      url = "https://github.com/BarutSRB/OmniWM/releases/download/v${version}/OmniWM-v${version}.zip";
      hash = "sha256-V0Zj6P94iAou3rYpA+CCz1Vq8Ko3cETuzFtveGD4idc=";
      appName = "OmniWM";
      description = "Tiling window manager for macOS with a Niri-inspired column layout";
      homepage = "https://github.com/BarutSRB/OmniWM";
      nativeBuildInputs = [ super.unzip ];
      updateScript = updateOmniWMScript;
      extraInstall = ''
        mkdir -p "$out/bin"
        ln -s "$out/Applications/OmniWM.app/Contents/MacOS/omniwmctl" "$out/bin/omniwmctl"
      '';
    };

    stremio = mkDarwinApp rec {
      pname = "stremio";
      version = "5.1.21";
      url = "https://dl.strem.io/stremio-shell-macos/v${version}/Stremio_${if super.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}.dmg";
      hash = if super.stdenv.hostPlatform.isAarch64
        then "sha256-gG4eJRBkm04PK1ecMEoYTuc0JHIN4N795plUgXL9ySk="
        else "sha256-0lx/XV/ya3NcaQEU9oCcr/79S7Qrq4vylawVqJn0cMY=";
      appName = "Stremio";
      description = "Open-source media center";
      homepage = "https://www.strem.io/";
      nativeBuildInputs = [ super._7zz ];
      updateScript = updateStremioScript;
    };

    sublimeText = mkDarwinApp rec {
      pname = "sublime-text";
      version = "4200";
      url = "https://download.sublimetext.com/sublime_text_build_${version}_mac.zip";
      hash = "sha256-SDXrKl0/KyI86TonFJ82DvFYr5+N1wi29QHXCMCB0xk=";
      appName = "Sublime Text";
      description = "Text editor for code, markup and prose";
      homepage = "https://www.sublimetext.com/";
      nativeBuildInputs = [ super.unzip ];
      updateScript = updateSublimeTextScript;
      extraInstall = ''
        mkdir -p "$out/bin"
        ln -s "$out/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" "$out/bin/subl"
      '';
    };

    "sublime-text" = sublimeText;
  };
in
linuxAttrs // darwinAttrs
