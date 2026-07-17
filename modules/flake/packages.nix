{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  darwinSystems = [ "aarch64-darwin" ];
  nixpkgsPolicy = import ../../lib/nixpkgs.nix { inherit inputs; };
  mkConfiguredPkgs = nixpkgsPolicy.mkPkgs;
  localPackageNamesFor = system:
    [
      "feather-font"
      "helium"
      "oh-my-codex-sidecar"
      "oh-my-claude-sisyphus-sidecar"
    ]
    ++ nixpkgs.lib.optionals (nixpkgs.lib.elem system darwinSystems) [
      "helium-browser"
      "omniwm"
      "raycast"
      "stremio"
      "sublimeText"
      "sublime-text"
    ];
  mkLocalPackages = system:
    let
      pkgs = mkConfiguredPkgs system;
      packageOrNull = name: pkgs.${name} or null;
    in
    nixpkgs.lib.filterAttrs (_name: value: value != null)
      (nixpkgs.lib.genAttrs (localPackageNamesFor system) packageOrNull);
in {
  perSystem = { system, ... }: {
    packages = mkLocalPackages system;
  };
}
