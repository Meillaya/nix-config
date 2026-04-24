self: super:
let
  version = "0.11.3.2";
  sources = {
    x86_64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/0.11.3.2/helium-0.11.3.2-x86_64.AppImage";
      sha256 = "0w1q106i1cvgi0dxmw69dywv0xi6m3kjy4gxlnhmsrbn1lm741z6";
    };
    aarch64-linux = {
      url = "https://github.com/imputnet/helium-linux/releases/download/0.11.3.2/helium-0.11.3.2-arm64.AppImage";
      sha256 = "1w5yi80p5djnsbwisb47q44i5yzchql7iffvyy9gi6l5nh3i7mlk";
    };
  };
  system = super.stdenv.hostPlatform.system;
  source =
    sources.${system} or (throw "helium is only packaged for Linux in this overlay");
in
{
  helium = super.appimageTools.wrapType2 rec {
    pname = "helium";
    inherit version;

    src = super.fetchurl source;

    extraInstallCommands = ''
      if [ -f "$out/share/applications/helium.desktop" ]; then
        substituteInPlace "$out/share/applications/helium.desktop" \
          --replace-fail 'Exec=AppRun' 'Exec=helium'
      fi
    '';

    meta = with super.lib; {
      description = "Private, fast, and honest web browser";
      homepage = "https://github.com/imputnet/helium-linux";
      downloadPage = "https://github.com/imputnet/helium-linux/releases";
      license = [ licenses.gpl3Only licenses.bsd3 ];
      platforms = builtins.attrNames sources;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      mainProgram = "helium";
    };
  };
}
