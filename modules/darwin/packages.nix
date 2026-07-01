{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; includeDocker = false; }; in
shared-packages ++ [
  # App replacements formerly installed as casks
  ghostty-bin
  iterm2
  obsidian
  postman
  raycast
  vesktop

  # Development tools
  cocoapods
  dockutil
  helix
  micro
  neovim
  omniorb
  uv
]
