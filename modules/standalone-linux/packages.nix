{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  brightnessctl
  cliphist
  fontconfig
  fuzzel
  gimp
  ghostty
  keepassxc
  libnotify
  mako
  obsidian
  pavucontrol
  playerctl
  qbittorrent
  swaybg
  waybar
  wl-clipboard
  wlogout
  wofi
  xdg-utils
  zathura
]
