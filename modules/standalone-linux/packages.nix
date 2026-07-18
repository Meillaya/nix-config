{ pkgs, inputs }:

let
  shared-packages = import ../shared/packages.nix {
    inherit pkgs;
    includeOpencode = false;
  };
  linux-packages = import ../linux/packages.nix {
    inherit pkgs;
  };
in
shared-packages ++ linux-packages ++ [
  inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
]
