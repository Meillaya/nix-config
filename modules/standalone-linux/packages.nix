{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  brightnessctl
  cliphist
  fontconfig
  fuzzel
  ghostty
  keepassxc
  libnotify
  mako
  pavucontrol
  playerctl
  swaybg
  waybar
  wl-clipboard
  wlogout
  wofi
  xdg-utils
  zathura
]
