{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
pkgs.lib.unique (shared-packages
  ++ (import ../shared/application-packages.nix { inherit pkgs; profile = "linux-desktop"; })
  ++ [

  # Security and authentication
  yubikey-agent
  keepassxc

  # App and package management
  appimage-run
  gnumake
  cmake
  home-manager

  # Media and design tools
  fontconfig

  # Wayland/Niri desktop
  awww
  brightnessctl
  cliphist
  ddcutil
  fuzzel
  kdePackages.konsole
  kdePackages.polkit-kde-agent-1

  # KDE file manager, document viewer, and Sweet/Dr460nized Qt theming
  kdePackages.ark
  kdePackages.dolphin
  kdePackages.dolphin-plugins
  kdePackages.ffmpegthumbs
  kdePackages.kio-admin
  kdePackages.kio-extras
  kdePackages.okular
  kdePackages.qt6ct
  kdePackages.qtstyleplugin-kvantum
  libsForQt5.qt5ct
  libsForQt5.qtstyleplugin-kvantum
  mako
  niri
  playerctl
  waybar
  wl-clipboard
  wlogout
  wofi
  xwayland-satellite

  # Productivity tools
  calibre
  gimp
  ghostty
  helium
  kitty
  obsidian
  ollama
  qbittorrent
  swaybg

  # Audio tools
  pavucontrol # Pulse audio controls

  # Testing and development tools
  rofi
  rofi-calc
  libtool # for Emacs vterm

  # Screenshot and recording tools
  flameshot

  # Text and terminal utilities
  tree
  unixtools.ifconfig
  unixtools.netstat
  xclip # For the org-download package in Emacs
  xwininfo # Provides a cursor to click and learn about windows
  xrandr

  # File and system utilities
  inotify-tools # inotifywait, inotifywatch - For file system events
  libnotify
  pcmanfm # File browser
  sqlite
  xdg-utils

  # Other utilities
  google-chrome

  # PDF viewer
  zathura

  # Development tools
  firefox

  # Music and entertainment
])
