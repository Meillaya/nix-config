{ pkgs, inputs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  brightnessctl
  brave
  calibre
  cliphist
  fontconfig
  fuzzel
  gimp
  ghostty
  keepassxc
  libnotify
  mako
  obsidian
  ollama
  pavucontrol
  playerctl
  qbittorrent
  swaybg
  tailscale
  waybar
  wl-clipboard
  wlogout
  wofi
  xdg-utils
  zathura
  opencode
  inputs.zen-browser.packages.${pkgs.system}.default
]
