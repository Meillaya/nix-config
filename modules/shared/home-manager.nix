{ config, pkgs, lib, ... }:

let
    user = config.home.username or "mei";
    gitName = "Meillaya";
    gitEmail = "nathanagbomed@proton.me";
    yaziPalette = {
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      overlay1 = "#7f849c";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };
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
    # macOS still ships /bin/bash 3.2, which does not understand Home
    # Manager's bash-completion guard (`[[ -v ... ]]`) or newer shopts.
    enableCompletion = !pkgs.stdenv.hostPlatform.isDarwin;
    shellOptions = [ "histappend" "extglob" ]
      ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ "globstar" "checkjobs" ];
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
    bashrcExtra = ''
      if [[ $- == *i* && -t 1 && "''${TERM:-}" != "dumb" && -z "''${FASTFETCH_SHELL_INIT_DONE:-}" ]] && command -v fastfetch >/dev/null 2>&1; then
        export FASTFETCH_SHELL_INIT_DONE=1
        fastfetch_config="$HOME/.config/fastfetch/config.jsonc"
        if [[ ("''${TERM_PROGRAM-}" == ghostty || "''${TERM-}" == xterm-ghostty) && -r "$HOME/.config/fastfetch/ghostty.jsonc" ]]; then
          fastfetch_config="$HOME/.config/fastfetch/ghostty.jsonc"
        fi
        fastfetch --config "$fastfetch_config"
        echo
      fi
    '';
    initExtra = ''
      if [[ "$(uname)" == Linux && -n "''${WAYLAND_DISPLAY-}" ]]; then
        current_display="''${DISPLAY-}"
        current_socket=""
        if [[ -n "$current_display" && "$current_display" == :* ]]; then
          display_num="''${current_display#:}"
          display_num="''${display_num%%.*}"
          current_socket="/tmp/.X11-unix/X$display_num"
        fi
        if [[ -z "$current_display" || ! -S "$current_socket" ]]; then
          if [[ -S /tmp/.X11-unix/X0 ]]; then
            export DISPLAY=:0
          fi
        fi
      fi

      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

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

      fastfetch() {
          local arg
          local fastfetch_config=""
          for arg in "$@"; do
              case "$arg" in
                  -c|--config|--config=*) command fastfetch "$@"; return ;;
              esac
          done

          if [[ "''${TERM_PROGRAM-}" == ghostty || "''${TERM-}" == xterm-ghostty ]]; then
              fastfetch_config="$HOME/.config/fastfetch/ghostty.jsonc"
          elif [[ -n "''${KITTY_PID-}" || -n "''${KITTY_WINDOW_ID-}" || "''${TERM-}" == xterm-kitty ]]; then
              fastfetch_config="$HOME/.config/fastfetch/kitty.jsonc"
          elif [[ -n "''${KONSOLE_VERSION-}" ]]; then
              fastfetch_config="$HOME/.config/fastfetch/konsole.jsonc"
          fi

          if [[ -n "$fastfetch_config" && -r "$fastfetch_config" ]]; then
              command fastfetch --config "$fastfetch_config" "$@"
          else
              command fastfetch "$@"
          fi
      }
    '';
  };

  fish = {
    enable = true;
    # fish 4.8.0 dropped `share/fish/tools/create_manpage_completions.py`,
    # which home-manager's auto-generated completion step calls for every
    # package with a manpage. Disable until upstream lands a 4.8-compatible
    # generator. Static `share/fish/vendor_completions.d/` files still work;
    # add hand-rolled entries under `programs.fish.completions` as needed.
    generateCompletions = false;
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
      fastfetch.body = ''
        set -l fastfetch_config ""

        for arg in $argv
          switch $arg
            case -c --config '--config=*'
              command fastfetch $argv
              return
          end
        end

        if test "$TERM_PROGRAM" = ghostty -o "$TERM" = xterm-ghostty
          set fastfetch_config "$HOME/.config/fastfetch/ghostty.jsonc"
        else if test -n "$KITTY_PID" -o -n "$KITTY_WINDOW_ID" -o "$TERM" = xterm-kitty
          set fastfetch_config "$HOME/.config/fastfetch/kitty.jsonc"
        else if test -n "$KONSOLE_VERSION"
          set fastfetch_config "$HOME/.config/fastfetch/konsole.jsonc"
        end

        if test -n "$fastfetch_config" -a -r "$fastfetch_config"
          command fastfetch --config "$fastfetch_config" $argv
        else
          command fastfetch $argv
        end
      '';
    };
    shellInit = ''
      if test (uname) = Linux; and test -n "$WAYLAND_DISPLAY"
        set -l current_display "$DISPLAY"
        set -l current_socket ""
        if string match -rq '^:[0-9]+' -- "$current_display"
          set -l display_num (string replace -r '^:([0-9]+).*' '$1' -- "$current_display")
          set current_socket "/tmp/.X11-unix/X$display_num"
        end
        if test -z "$current_display"; or not test -S "$current_socket"
          if test -S /tmp/.X11-unix/X0
            set -gx DISPLAY :0
          end
        end
      end

      if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      else if test -f /nix/var/nix/profiles/default/etc/profile.d/nix.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix.fish
      end

      if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        source /usr/share/cachyos-fish-config/cachyos-config.fish
      end

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

      if status is-interactive; and test -t 1; and test "$TERM" != dumb; and test -z "$FASTFETCH_SHELL_INIT_DONE"; and command -q fastfetch
        set -gx FASTFETCH_SHELL_INIT_DONE 1
        set -l fastfetch_config "$HOME/.config/fastfetch/config.jsonc"
        if test "$TERM_PROGRAM" = ghostty -o "$TERM" = xterm-ghostty; and test -r "$HOME/.config/fastfetch/ghostty.jsonc"
          set fastfetch_config "$HOME/.config/fastfetch/ghostty.jsonc"
        end
        fastfetch --config "$fastfetch_config"
        echo
      end
    '';
  };

  zsh = {
    enable = true;
    # Adopt the XDG layout: zsh dotfiles live under ~/.config/zsh/.
    # HM exports $ZDOTDIR for us so zsh reads from there automatically.
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    envExtra = ''
      # Home Manager owns zsh startup; skip global zshrc files before
      # Powerlevel10k instant prompt.
      unsetopt GLOBAL_RCS
    '';
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
      ] ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
        "docker"
        "docker-compose"
      ] ++ [
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
        ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh-${pkgs.stdenv.hostPlatform.system}-hm-v2"
        ZSH_COMPDUMP="$HOME/.cache/zsh/.zcompdump-${pkgs.stdenv.hostPlatform.system}-hm-v2-$ZSH_VERSION"
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
        if [[ "$(uname)" == Linux && -n "''${WAYLAND_DISPLAY-}" ]]; then
          current_display="''${DISPLAY-}"
          current_socket=""
          if [[ -n "$current_display" && "$current_display" == :* ]]; then
            display_num="''${current_display#:}"
            display_num="''${display_num%%.*}"
            current_socket="/tmp/.X11-unix/X$display_num"
          fi
          if [[ -z "$current_display" || ! -S "$current_socket" ]]; then
            if [[ -S /tmp/.X11-unix/X0 ]]; then
              export DISPLAY=:0
            fi
          fi
        fi

        if [[ -o interactive && -t 1 && "''${TERM:-}" != "dumb" && -z "''${FASTFETCH_SHELL_INIT_DONE:-}" ]] && command -v fastfetch >/dev/null 2>&1; then
          export FASTFETCH_SHELL_INIT_DONE=1
          fastfetch_config="$HOME/.config/fastfetch/config.jsonc"
          if [[ ("''${TERM_PROGRAM-}" == ghostty || "''${TERM-}" == xterm-ghostty) && -r "$HOME/.config/fastfetch/ghostty.jsonc" ]]; then
            fastfetch_config="$HOME/.config/fastfetch/ghostty.jsonc"
          fi
          fastfetch --config "$fastfetch_config"
          echo
        fi

        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
        fi

        # Define variables for directories
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

        # Start from a deterministic function search path so nested shells do
        # not inherit stale oh-my-zsh plugin completion paths.
        fpath=("${pkgs.zsh}/share/zsh/$ZSH_VERSION/functions")

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

        fastfetch() {
            local arg
            local fastfetch_config=""
            for arg in "$@"; do
                case "$arg" in
                    -c|--config|--config=*) command fastfetch "$@"; return ;;
                esac
            done

            if [[ "''${TERM_PROGRAM-}" == ghostty || "''${TERM-}" == xterm-ghostty ]]; then
                fastfetch_config="$HOME/.config/fastfetch/ghostty.jsonc"
            elif [[ -n "''${KITTY_PID-}" || -n "''${KITTY_WINDOW_ID-}" || "''${TERM-}" == xterm-kitty ]]; then
                fastfetch_config="$HOME/.config/fastfetch/kitty.jsonc"
            elif [[ -n "''${KONSOLE_VERSION-}" ]]; then
                fastfetch_config="$HOME/.config/fastfetch/konsole.jsonc"
            fi

            if [[ -n "$fastfetch_config" && -r "$fastfetch_config" ]]; then
                command fastfetch --config "$fastfetch_config" "$@"
            else
                command fastfetch "$@"
            fi
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

  yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    shellWrapperName = "yy";

    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
      yatline = pkgs.yaziPlugins.yatline;
    };

    settings = {
      mgr = {
        ratio = [ 1 3 4 ];
        sort_by = "natural";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        sort_translit = true;
        sort_fallback = "alphabetical";
        linemode = "size";
        show_hidden = false;
        show_symlink = true;
        scrolloff = 8;
        mouse_events = [ "click" "scroll" "drag" ];
      };

      preview = {
        wrap = "no";
        tab_size = 2;
        max_width = 1000;
        max_height = 1200;
        image_delay = 20;
        image_filter = "lanczos3";
        image_quality = 85;
      };

      input = {
        cursor_blink = true;
        cd_origin = "top-center";
        create_origin = "top-center";
        filter_origin = "top-center";
        find_origin = "top-center";
        search_origin = "top-center";
        shell_origin = "top-center";
      };
    };

    keymap = {
      mgr.append_keymap = [
        { on = [ "g" "p" ]; run = "cd ~/Projects"; desc = "Go ~/Projects"; }
        { on = [ "g" "D" ]; run = "cd ~/Documents"; desc = "Go ~/Documents"; }
        { on = [ "g" "m" ]; run = "cd ~/Music"; desc = "Go ~/Music"; }
        { on = [ "g" "n" ]; run = "cd /nix/store"; desc = "Go /nix/store"; }
        { on = [ "g" "l" ]; run = "cd ~/.local/share"; desc = "Go ~/.local/share"; }
        { on = [ "g" "b" ]; run = "cd ~/.local/bin"; desc = "Go ~/.local/bin"; }
      ];
    };

    # Use the upstream `noctalia` flavor (yazi v25+ feature) instead of a
    # hand-rolled theme. The flavor must be present at runtime in
    # $XDG_CONFIG_HOME/yazi/flavors/ (or yazi's system flavor dir); noctalia
    # ships it. See <https://yazi-rs.github.io/docs/flavors/overview>.
    theme = {
      flavor = {
        dark = "noctalia";
        light = "noctalia";
      };
    };

    initLua = ''
      require("full-border"):setup({ type = ui.Border.ROUNDED })

      require("yatline"):setup({
        section_separator = { open = "", close = "" },
        part_separator = { open = "", close = "" },
        inverse_separator = { open = "", close = "" },
        padding = { inner = 1, outer = 0 },

        style_a = {
          fg = "${yaziPalette.base}",
          bg = "${yaziPalette.mauve}",
          bg_mode = {
            normal = "${yaziPalette.mauve}",
            select = "${yaziPalette.peach}",
            un_set = "${yaziPalette.red}",
          },
        },
        style_b = { fg = "${yaziPalette.text}", bg = "${yaziPalette.surface1}" },
        style_c = { fg = "${yaziPalette.subtext1}", bg = "${yaziPalette.mantle}" },

        permissions_t_fg = "${yaziPalette.green}",
        permissions_r_fg = "${yaziPalette.yellow}",
        permissions_w_fg = "${yaziPalette.red}",
        permissions_x_fg = "${yaziPalette.sky}",
        permissions_s_fg = "${yaziPalette.overlay1}",

        selected = { icon = "󰻭", fg = "${yaziPalette.yellow}" },
        copied = { icon = "", fg = "${yaziPalette.green}" },
        cut = { icon = "", fg = "${yaziPalette.red}" },
        files = { icon = "󰈔", fg = "${yaziPalette.blue}" },
        filtereds = { icon = "", fg = "${yaziPalette.mauve}" },
        total = { icon = "󰮍", fg = "${yaziPalette.yellow}" },
        success = { icon = "", fg = "${yaziPalette.green}" },
        failed = { icon = "", fg = "${yaziPalette.red}" },

        show_background = true,
        display_header_line = true,
        display_status_line = true,
        component_positions = { "header", "tab", "status" },
        tab_width = 18,

        header_line = {
          left = {
            section_a = {
              { type = "line", name = "tabs" },
            },
            section_b = {
              { type = "string", name = "tab_path", params = { true, 48, 16 } },
            },
            section_c = {},
          },
          right = {
            section_a = {
              { type = "string", name = "date", params = { "%H:%M" } },
            },
            section_b = {
              { type = "string", name = "date", params = { "%a %d %b" } },
            },
            section_c = {},
          },
        },

        status_line = {
          left = {
            section_a = {
              { type = "string", name = "tab_mode" },
            },
            section_b = {
              { type = "string", name = "hovered_size" },
            },
            section_c = {
              { type = "string", custom = true, name = "󰌌 q quit · ~ help · / find · s search · z fzf · Z zoxide · Space select" },
            },
          },
          right = {
            section_a = {
              { type = "string", name = "cursor_position" },
            },
            section_b = {
              { type = "string", name = "cursor_percentage" },
            },
            section_c = {
              { type = "coloreds", name = "count" },
              { type = "coloreds", name = "permissions" },
            },
          },
        },
      })
    '';
  };

  git = {
    enable = true;
    ignores = [ "*.swp" "**/.claude/settings.local.json" ];
    lfs = {
      enable = true;
    };
    signing = {
      format = "openpgp";
      key = "15E95E5E02E51FBDA521A8FE134771C79E4A74F2";
    };
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

  fastfetch = {
    enable = true;
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
