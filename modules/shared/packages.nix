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
        export SHELL="${zsh}/bin/zsh"
        export OMX_ENTRY_PATH="$cli"
        export OMX_STARTUP_CWD="$PWD"
        exec ${nodejs_24}/bin/node "$cli" "$@"
      fi
    done

    echo "omx is not installed in a known global node location." >&2
    echo "Expected oh-my-codex under npm global packages, /opt/homebrew, or /opt/zerobrew." >&2
    exit 127
  '';
  omcLauncher = writeShellScriptBin "omc" ''
    set -euo pipefail

    candidates=()
    npm_root="$(${nodejs_24}/bin/npm root -g 2>/dev/null || true)"

    if [ -n "$npm_root" ]; then
      candidates+=("$npm_root/oh-my-claude-sisyphus")
    fi

    for dir in \
      "$HOME/.local/lib/node_modules/oh-my-claude-sisyphus" \
      "$HOME/.npm-packages/lib/node_modules/oh-my-claude-sisyphus" \
      "$HOME/.local/share/pnpm/global/5/node_modules/oh-my-claude-sisyphus"
    do
      if [ -d "$dir" ]; then
        candidates+=("$dir")
      fi
    done

    for dir in "''${candidates[@]}"; do
      cli="$dir/bridge/cli.cjs"
      if [ -f "$cli" ]; then
        exec ${nodejs_24}/bin/node "$cli" "$@"
      fi
    done

    echo "omc is not installed in a known global node location." >&2
    echo "Expected oh-my-claude-sisyphus under npm global packages or ~/.local/lib/node_modules." >&2
    exit 127
  '';
  syncAiSidecars = writeShellScriptBin "sync-ai-sidecars" ''
    set -euo pipefail

    prefix="''${AI_SIDECAR_PREFIX:-$HOME/.local}"
    ${nodejs_24}/bin/npm install --global --prefix "$prefix" \
      oh-my-codex@0.14.4 \
      oh-my-claude-sisyphus@4.13.3
  '';
  nixpkgsSearch = writeShellScriptBin "nixpkgs-search" ''
    set -euo pipefail

    unstable_ref="''${NIXPKGS_SEARCH_UNSTABLE_REF:-github:nixos/nixpkgs/nixos-unstable}"
    stable_ref="''${NIXPKGS_SEARCH_STABLE_REF:-github:nixos/nixpkgs/nixos-25.11}"
    limit="''${NIXPKGS_SEARCH_LIMIT:-20}"
    query_args=()

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --stable-ref)
          stable_ref="$2"
          shift 2
          ;;
        --unstable-ref)
          unstable_ref="$2"
          shift 2
          ;;
        --limit)
          limit="$2"
          shift 2
          ;;
        --help|-h)
          cat <<'EOF'
Usage: nixpkgs-search [--stable-ref REF] [--unstable-ref REF] [--limit N] QUERY...

Searches both stable and unstable nixpkgs and prints a compact comparison.

Environment overrides:
  NIXPKGS_SEARCH_STABLE_REF
  NIXPKGS_SEARCH_UNSTABLE_REF
  NIXPKGS_SEARCH_LIMIT

Examples:
  nixpkgs-search wezterm
  nixpkgs-search --stable-ref github:nixos/nixpkgs/nixos-25.05 lua language server
EOF
          exit 0
          ;;
        *)
          query_args+=("$1")
          shift
          ;;
      esac
    done

    if [ "''${#query_args[@]}" -eq 0 ]; then
      echo "nixpkgs-search: missing search query" >&2
      echo "Run 'nixpkgs-search --help' for usage." >&2
      exit 2
    fi

    query="''${query_args[*]}"

    search_ref() {
      local label="$1"
      local ref="$2"
      local json

      printf '\n%s\n' "== $label =="
      printf '%s\n' "ref: $ref"

      if ! json="$(${nix}/bin/nix --extra-experimental-features 'nix-command flakes' search --json "$ref" "$query" 2>/dev/null)"; then
        echo "search failed for $label" >&2
        return 1
      fi

      if [ "$(${jq}/bin/jq 'length' <<<"$json")" -eq 0 ]; then
        echo "no matches"
        return 0
      fi

      ${jq}/bin/jq -r --argjson limit "$limit" '
        to_entries
        | sort_by(.key)
        | .[:$limit]
        | .[]
        | [
            .key,
            (.value.version // "-"),
            (.value.description // "-" | gsub("[\r\n\t]+"; " "))
          ]
        | @tsv
      ' <<<"$json" | while IFS=$'\t' read -r attr version description; do
        printf '%-45s %-18s %s\n' "$attr" "$version" "$description"
      done
    }

    search_ref "unstable" "$unstable_ref"
    search_ref "stable" "$stable_ref"
  '';
in [
  # General packages for development and system management
  alacritty
  bash-completion
  bat
  bear
  btop
  bun
  ccache
  coreutils
  duf
  fastfetch
  gdb
  killall
  openssh
  pipx
  resvg
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
  glances
  micro
  ripgrep
  tectonic
  tokei
  tree
  tmux
  unrar
  unzip
  yazi
  zoxide
  zsh-powerlevel10k
  
  # Development tools
  curl
  gh
  terraform
  kubectl
  awscli2
  claude-code
  codex
  lazygit
  fzf
  direnv
  flyctl
  podman
  zed-editor
  
  # Programming languages and runtimes
  elixir
  erlang
  go
  iverilog
  gopls
  jdt-language-server
  nil
  nixd
  basedpyright
  rustc
  cargo
  rust-analyzer
  openjdk
  pandoc
  taplo
  typescript-language-server
  valkey
  vscode-langservers-extracted
  yaml-language-server
  zls

  # Python packages
  python3
  virtualenv
  zig
  omcLauncher
  omxLauncher
  syncAiSidecars
  nixpkgsSearch
]
