{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # Development tools
  cocoapods
  dockutil
  helix
  micro
  neovim
  omniorb
  uv
]
