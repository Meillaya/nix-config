{ inputs }:
let
  localOverlayDirectory = ../overlays;
  localOverlayFiles = builtins.filter
    (name:
      builtins.match ".*\\.nix" name != null
      || builtins.pathExists (localOverlayDirectory + "/${name}/default.nix"))
    (builtins.attrNames (builtins.readDir localOverlayDirectory));
  overlays =
    map (name: import (localOverlayDirectory + "/${name}")) localOverlayFiles
    ++ [ (import inputs.emacs-overlay) ];
  config = {
    allowUnfree = true;
    allowBroken = true;
    allowInsecure = false;
    permittedInsecurePackages = [ "pnpm-10.29.2" ];
    allowUnsupportedSystem = true;
  };
in
{
  inherit config overlays;
  mkPkgs = system: import inputs.nixpkgs { inherit system config overlays; };
}
