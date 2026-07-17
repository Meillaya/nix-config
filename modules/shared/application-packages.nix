{ pkgs, profile ? "portable" }:

let
  inherit (pkgs) lib;
  validProfiles = [ "portable" "linux-desktop" "wsl" "darwin" ];
  portable = with pkgs; [
    aria2
    bat
    btop
    bun
    cmake
    curl
    eza
    fastfetch
    fd
    ffmpeg
    fzf
    git
    go
    helix
    htop
    kubectl
    lazygit
    micro
    ncdu
    neovim
    nodejs_24
    opencode
    pnpm
    python3
    ranger
    restic
    ripgrep
    rsync
    rustup
    superfile
    tldr
    tmux
    uv
    wget
    yazi
    zellij
    zoxide
  ];
  linuxCli = with pkgs; [
    docker
    incus
    llama-cpp
    ollama
    podman
  ];
  linuxDesktop = with pkgs; [
    bitwarden-desktop
    bruno
    conky
    dbeaver-bin
    flameshot
    fsearch
    halloy
    hoppscotch
    imhex
    jetbrains.idea
    jetbrains.pycharm
    keepassxc
    kdePackages.partitionmanager
    meld
    mission-center
    obs-studio
    openrgb
    ptyxis
    vesktop
    virt-manager
    wireshark
    yaak
    zed-editor
  ];
  x86LinuxCli = with pkgs; [ vagrant ];
  x86LinuxDesktop = with pkgs; [ postman sublime4 ];
  darwinCompatible = with pkgs; [
    bitwarden-desktop
    bruno
    postman
    sublimeText
    vesktop
    zed-editor
  ];
in
assert lib.assertMsg (builtins.elem profile validProfiles)
  "unknown application package profile: ${profile}";
lib.unique (
  portable
  ++ lib.optionals (profile == "linux-desktop")
    (linuxCli ++ linuxDesktop
      ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (x86LinuxCli ++ x86LinuxDesktop))
  ++ lib.optionals (profile == "wsl")
    (linuxCli ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 x86LinuxCli)
  ++ lib.optionals (profile == "darwin") darwinCompatible
)
