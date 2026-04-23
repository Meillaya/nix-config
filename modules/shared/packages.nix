{ pkgs }:

with pkgs;
let
  omxLauncher = writeShellScriptBin "omx" ''
    set -euo pipefail

    candidates=()
    npm_root="$(${nodejs_24}/bin/npm root -g 2>/dev/null || true)"

    if [ -n "$npm_root" ]; then
      candidates+=("$npm_root/oh-my-codex")
    fi

    for dir in \
      /opt/homebrew/lib/node_modules/oh-my-codex \
      "$HOME/.npm-packages/lib/node_modules/oh-my-codex" \
      "$HOME/.local/share/pnpm/global/5/node_modules/oh-my-codex"
    do
      if [ -d "$dir" ]; then
        candidates+=("$dir")
      fi
    done

    for dir in /opt/zerobrew/Cellar/node/*/lib/node_modules/oh-my-codex; do
      if [ -d "$dir" ]; then
        candidates+=("$dir")
      fi
    done

    for dir in "''${candidates[@]}"; do
      cli="$dir/dist/cli/omx.js"
      if [ -x "$cli" ]; then
        export OMX_ENTRY_PATH="$cli"
        export OMX_STARTUP_CWD="$PWD"
        exec ${nodejs_24}/bin/node "$cli" "$@"
      fi
    done

    echo "omx is not installed in a known global node location." >&2
    echo "Expected oh-my-codex under npm global packages, /opt/homebrew, or /opt/zerobrew." >&2
    exit 127
  '';
in [
  # General packages for development and system management
  alacritty
  bash-completion
  bat
  btop
  coreutils
  killall
  openssh
  sqlite
  wget
  zip

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Cloud-related tools and SDKs
  docker
  docker-compose

  # Media-related packages
  emacs-all-the-icons-fonts
  dejavu_fonts
  ffmpeg
  fd
  font-awesome
  hack-font
  noto-fonts
  noto-fonts-color-emoji
  meslo-lgs-nf

  # Node.js development tools
  nodejs_24

  # Text and terminal utilities
  htop
  jetbrains-mono
  jq
  ripgrep
  tree
  tmux
  unrar
  unzip
  zsh-powerlevel10k
  
  # Development tools
  curl
  gh
  terraform
  kubectl
  awscli2
  lazygit
  fzf
  direnv
  
  # Programming languages and runtimes
  go
  rustc
  cargo
  openjdk

  # Python packages
  python3
  virtualenv
  omxLauncher
]
