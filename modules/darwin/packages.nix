{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; includeDocker = false; }; in
shared-packages ++ [
  # App replacements formerly installed as casks
  ghostty-bin
  helium
  iterm2
  kitty
  obsidian
  omniwm
  postman
  raycast
  stremio
  sublimeText
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
