{ config, pkgs, lib, ... }:

let
    user = config.home.username or "mei";
    gitName = "Meillaya";
    gitEmail = "nathanagbomed@proton.me";
in
{
  # Shared shell configuration
  readline = {
    enable = true;
    variables = {
      completion-ignore-case = true;
      show-all-if-ambiguous = true;
      colored-stats = true;
      mark-symlinked-directories = true;
      menu-complete-display-prefix = true;
    };
    bindings = {
      "\\e[A" = "history-search-backward";
      "\\e[B" = "history-search-forward";
      "\\eOA" = "history-search-backward";
      "\\eOB" = "history-search-forward";
    };
  };

  bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoreboth" "erasedups" ];
    historyIgnore = [ "pwd" "ls" "cd" ];
    shellAliases = {
      pn = "pnpm";
      px = "pnpx";
      diff = "difft";
      grep = "grep --color=auto";
      ls = "ls --color=auto";
      search = "rg -p --glob '!node_modules/*'";
    };
    initExtra = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
      ''}
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH

      export ALTERNATE_EDITOR=""
      export EDITOR="emacsclient -t"
      export VISUAL="emacsclient -c -a emacs"

      [[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
      [[ -f "$HOME/.ghcup/env" ]] && . "$HOME/.ghcup/env"

      e() {
          emacsclient -t "$@"
      }

      shell() {
          nix-shell '<nixpkgs>' -A "$1"
      }
    '';
  };

  fish = {
    enable = true;
    generateCompletions = true;
    shellAliases = {
      pn = "pnpm";
      px = "pnpx";
      diff = "difft";
      ls = "ls --color=auto";
      search = "rg -p --glob '!node_modules/*'";
    };
    functions = {
      e.body = ''
        emacsclient -t $argv
      '';
      shell.body = ''
        nix-shell '<nixpkgs>' -A $argv[1]
      '';
    };
    shellInit = ''
      if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      else if test -f /nix/var/nix/profiles/default/etc/profile.d/nix.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix.fish
      end

      if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        source /usr/share/cachyos-fish-config/cachyos-config.fish
      end

      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      fish_add_path --prepend /opt/homebrew/bin /opt/homebrew/sbin
      ''}
      fish_add_path --prepend $HOME/.pnpm-packages/bin $HOME/.pnpm-packages
      fish_add_path --prepend $HOME/.npm-packages/bin $HOME/bin
      fish_add_path --prepend $HOME/.local/bin
      fish_add_path --prepend $HOME/.local/share/bin
      fish_add_path --prepend $HOME/.cabal/bin $HOME/.ghcup/bin
      fish_add_path --prepend $HOME/.spicetify

      test -r "$HOME/.opam/opam-init/init.fish" && source "$HOME/.opam/opam-init/init.fish" > /dev/null 2> /dev/null; or true

      set -gx ALTERNATE_EDITOR ""
      set -gx EDITOR "emacsclient -t"
      set -gx VISUAL "emacsclient -c -a emacs"
    '';
  };

  zsh = {
    enable = true;
    enableCompletion = true;
    autocd = false;
    cdpath = [ "~/Projects" ];
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
      highlight = "fg=8";
    };
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "$terminfo[kcuu1]" "^[[A" ];
      searchDownKey = [ "$terminfo[kcud1]" "^[[B" ];
    };
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "aws"
        "direnv"
        "docker"
        "docker-compose"
        "gh"
        "kubectl"
        "terraform"
        "tmux"
      ];
      extraConfig = ''
        DISABLE_AUTO_UPDATE="true"
        DISABLE_UPDATE_PROMPT="true"
        CASE_SENSITIVE="false"
        HYPHEN_INSENSITIVE="true"
        ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-$ZSH_VERSION"
      '';
    };
    plugins = [
      {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./config;
          file = "p10k.zsh";
      }
    ];
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        # Define variables for directories
        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
        ''}
        export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
        export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
        export PATH=$HOME/.local/bin:$PATH
        export PATH=$HOME/.local/share/bin:$PATH

        [[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
        [[ -f "$HOME/.ghcup/env" ]] && . "$HOME/.ghcup/env"
        [[ -f /usr/share/cachyos-zsh-config/cachyos-config.zsh ]] && source /usr/share/cachyos-zsh-config/cachyos-config.zsh

        # OMX/tmux launches source ~/.zshrc from non-interactive shells to recover
        # PATH. Stop here before interactive-only plugin/history/setopt setup.
        if [[ ! -o interactive ]]; then
          return
        fi

        # Remove history data we don't want to see
        export HISTIGNORE="pwd:ls:cd"

        # Ripgrep alias
        alias search=rg -p --glob '!node_modules/*'  $@

        # Emacs is my editor
        export ALTERNATE_EDITOR=""
        export EDITOR="emacsclient -t"
        export VISUAL="emacsclient -c -a emacs"

        e() {
            emacsclient -t "$@"
        }

        # nix shortcuts
        shell() {
            nix-shell '<nixpkgs>' -A "$1"
        }

        # pnpm is a javascript package manager
        alias pn=pnpm
        alias px=pnpx

        # Use difftastic, syntax-aware diffing
        alias diff=difft

        # Always color ls and group directories
        alias ls='ls --color=auto'
      '')

      (lib.mkOrder 850 ''
        mkdir -p "$HOME/.cache/zsh"
        zmodload zsh/complist

        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*' squeeze-slashes true
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "$HOME/.cache/zsh"
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*:warnings' format 'no matches for: %d'
      '')
    ];
  };

  git = {
    enable = true;
    ignores = [ "*.swp" "**/.claude/settings.local.json" ];
    lfs = {
      enable = true;
    };
    signing.format = "openpgp";
    settings = {
      user = {
        name = gitName;
        email = gitEmail;
      };
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      commit.gpgsign = true;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-airline vim-airline-themes vim-startify vim-tmux-navigator ];
    settings = { ignorecase = true; };
    extraConfig = ''
      "" General
      set number
      set history=1000
      set nocompatible
      set modelines=0
      set encoding=utf-8
      set scrolloff=3
      set showmode
      set showcmd
      set hidden
      set wildmenu
      set wildmode=list:longest
      set cursorline
      set ttyfast
      set nowrap
      set ruler
      set backspace=indent,eol,start
      set laststatus=2
      set clipboard=autoselect

      " Dir stuff
      set nobackup
      set nowritebackup
      set noswapfile
      set backupdir=~/.config/vim/backups
      set directory=~/.config/vim/swap

      " Relative line numbers for easy movement
      set relativenumber
      set rnu

      "" Whitespace rules
      set tabstop=8
      set shiftwidth=2
      set softtabstop=2
      set expandtab

      "" Searching
      set incsearch
      set gdefault

      "" Statusbar
      set nocompatible " Disable vi-compatibility
      set laststatus=2 " Always show the statusline
      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1

      "" Local keys and such
      let mapleader=","
      let maplocalleader=" "

      "" Change cursor on mode
      :autocmd InsertEnter * set cul
      :autocmd InsertLeave * set nocul

      "" File-type highlighting and configuration
      syntax on
      filetype on
      filetype plugin on
      filetype indent on

      "" Paste from clipboard
      nnoremap <Leader>, "+gP

      "" Copy from clipboard
      xnoremap <Leader>. "+y

      "" Move cursor by display lines when wrapping
      nnoremap j gj
      nnoremap k gk

      "" Map leader-q to quit out of window
      nnoremap <leader>q :q<cr>

      "" Move around split
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      "" Easier to yank entire line
      nnoremap Y y$

      "" Move buffers
      nnoremap <tab> :bnext<cr>
      nnoremap <S-tab> :bprev<cr>

      "" Like a boss, sudo AFTER opening the file to write
      cmap w!! w !sudo tee % >/dev/null

      let g:startify_lists = [
        \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
        \ { 'type': 'sessions',  'header': ['   Sessions']       },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
        \ ]

      let g:startify_bookmarks = [
        \ '~/Projects',
        \ '~/Documents',
        \ ]

      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1
      '';
     };

  alacritty = {
    enable = true;
    settings = {
      env = {
        TERM = "xterm-256color";
        WINIT_X11_SCALE_FACTOR = "1";
      };

      cursor = {
        style = "Underline";
        vi_mode_style = "None";
        unfocused_hollow = true;
        thickness = 0.15;
      };

      general = {
        live_config_reload = true;
        working_directory = "None";
      };

      keyboard.bindings = [
        { key = "Paste"; action = "Paste"; }
        { key = "Copy"; action = "Copy"; }
        { key = "L"; mods = "Control"; action = "ClearLogNotice"; }
        { key = "L"; mods = "Control"; mode = "~Vi"; chars = "\\f"; }
        { key = "PageUp"; mods = "Shift"; mode = "~Alt"; action = "ScrollPageUp"; }
        { key = "PageDown"; mods = "Shift"; mode = "~Alt"; action = "ScrollPageDown"; }
        { key = "Home"; mods = "Shift"; mode = "~Alt"; action = "ScrollToTop"; }
        { key = "End"; mods = "Shift"; mode = "~Alt"; action = "ScrollToBottom"; }
        { key = "V"; mods = "Control|Shift"; action = "Paste"; }
        { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        { key = "F"; mods = "Control|Shift"; action = "SearchForward"; }
        { key = "B"; mods = "Control|Shift"; action = "SearchBackward"; }
        { key = "C"; mods = "Control|Shift"; mode = "Vi"; action = "ClearSelection"; }
        { key = "Key0"; mods = "Control"; action = "ResetFontSize"; }
      ];

      mouse = {
        hide_when_typing = true;
        bindings = [
          { mouse = "Middle"; action = "PasteSelection"; }
        ];
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      selection = {
        semantic_escape_chars = ",│`|:\\\"' ()[]{}<>\\t";
        save_to_clipboard = true;
      };

      window = {
        dynamic_padding = true;
        decorations = "full";
        title = "Alacritty@CachyOS";
        opacity = 0.8;
        decorations_theme_variant = "Dark";
        dimensions = {
          columns = 100;
          lines = 30;
        };
        class = {
          instance = "Alacritty";
          general = "Alacritty";
        };
        padding = {
          x = 24;
          y = 24;
        };
      };

      # Fix for shell path when launching from desktop
      # When launching from desktop, $SHELL may point to /bin/zsh instead of
      # the Nix-managed shell, causing environment issues
      terminal.shell = {
        program = "${pkgs.zsh}/bin/zsh";
      };

      font = {
        normal = {
          family = "monospace";
          style = "Regular";
        };
        bold = {
          family = "monospace";
          style = "Bold";
        };
        italic = {
          family = "monospace";
          style = "Italic";
        };
        bold_italic = {
          family = "monospace";
          style = "Bold Italic";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 12)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
        ];
      };


      colors = {
        draw_bold_text_with_bright_colors = true;

        primary = {
          background = "0x2E3440";
          foreground = "0xD8DEE9";
        };

        normal = {
          black = "0x3B4252";
          red = "0xBF616A";
          green = "0xA3BE8C";
          yellow = "0xEBCB8B";
          blue = "0x81A1C1";
          magenta = "0xB48EAD";
          cyan = "0x88C0D0";
          white = "0xE5E9F0";
        };

        bright = {
          black = "0x4C566A";
          red = "0xBF616A";
          green = "0xA3BE8C";
          yellow = "0xEBCB8B";
          blue = "0x81A1C1";
          magenta = "0xB48EAD";
          cyan = "0x8FBCBB";
          white = "0xECEFF4";
        };
      };
    };
  };

  ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
    matchBlocks = {
      "*" = {
        # Set the default values we want to keep
        sendEnv = [ "LANG" "LC_*" ];
        hashKnownHosts = true;
      };
      "github.com" = {
        identitiesOnly = true;
        identityFile =
          if pkgs.stdenv.hostPlatform.isLinux then [
            "/home/${user}/.ssh/id_github"
            "/home/${user}/.ssh/id_ed25519"
          ] else [
            "/Users/${user}/.ssh/id_github"
            "/Users/${user}/.ssh/id_ed25519"
          ];
      };
    };
  };

  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
           set -g @tmux_power_theme 'gold'
        '';
      }
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-x";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Enable full mouse support
      set -g mouse on

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default keys
      unbind C-b
      unbind '"'
      unbind %

      # Split panes, vertical or horizontal
      bind-key x split-window -v
      bind-key v split-window -h

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # Smart pane switching with awareness of Vim splits.
      # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l
      '';
    };
}
