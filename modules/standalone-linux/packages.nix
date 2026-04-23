{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  fontconfig
  fuzzel
  keepassxc
  libnotify
  pavucontrol
  wl-clipboard
  xdg-utils
  zathura
]
