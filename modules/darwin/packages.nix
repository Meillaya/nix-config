{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; includeDocker = false; }; in
shared-packages ++ [
  # App replacements formerly installed as casks
  bruno
  dbeaver-bin
  ghostty-bin
  iterm2
  jetbrains.idea
  kitty
  postman
  vesktop

  # Development tools
  cocoapods
  dockutil
  helix
  micro
  neovim
  omniorb
  jetbrains.pycharm
  uv
]
