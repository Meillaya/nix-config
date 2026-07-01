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
      extraInstall = ''
        mkdir -p "$out/bin"
        ln -s "$out/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" "$out/bin/subl"
      '';
    };

    "sublime-text" = sublimeText;
  };
in
linuxAttrs // darwinAttrs
