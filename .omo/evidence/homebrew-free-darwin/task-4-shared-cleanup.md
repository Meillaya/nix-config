# Task 4 shared Homebrew cleanup evidence

## shared scan

## Nix parse
modules/shared/packages.nix parses
modules/shared/home-manager.nix parses

## diff
diff --git a/modules/shared/home-manager.nix b/modules/shared/home-manager.nix
index c9db529..7066280 100644
--- a/modules/shared/home-manager.nix
+++ b/modules/shared/home-manager.nix
@@ -94,9 +94,6 @@ in
         . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
       fi
 
-      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
-      export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
-      ''}
       export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
       export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
       export PATH=$HOME/.local/bin:$PATH
@@ -192,9 +189,6 @@ in
         source /usr/share/cachyos-fish-config/cachyos-config.fish
       end
 
-      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
-      fish_add_path --prepend /opt/homebrew/bin /opt/homebrew/sbin
-      ''}
       fish_add_path --prepend $HOME/.pnpm-packages/bin $HOME/.pnpm-packages
       fish_add_path --prepend $HOME/.npm-packages/bin $HOME/bin
       fish_add_path --prepend $HOME/.local/bin
@@ -224,8 +218,8 @@ in
     enable = true;
     enableCompletion = true;
     envExtra = ''
-      # Home Manager owns zsh startup; skip global zshrc files that can run
-      # unmanaged Homebrew completions before Powerlevel10k instant prompt.
+      # Home Manager owns zsh startup; skip global zshrc files before
+      # Powerlevel10k instant prompt.
       unsetopt GLOBAL_RCS
     '';
     autocd = false;
@@ -315,9 +309,6 @@ in
         fi
 
         # Define variables for directories
-        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
-        export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
-        ''}
         export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
         export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
         export PATH=$HOME/.local/bin:$PATH
diff --git a/modules/shared/packages.nix b/modules/shared/packages.nix
index 36cf6f9..411407e 100644
--- a/modules/shared/packages.nix
+++ b/modules/shared/packages.nix
@@ -10,7 +10,6 @@ let
         /bin/zsh \
         /usr/bin/zsh \
         /usr/local/bin/zsh \
-        /opt/homebrew/bin/zsh \
         /bin/bash \
         /usr/bin/bash
       do
@@ -38,7 +37,6 @@ let
 
     for dir in \
       "$HOME/.nix-profile/lib/node_modules/oh-my-codex" \
-      /opt/homebrew/lib/node_modules/oh-my-codex \
       "$HOME/.npm-packages/lib/node_modules/oh-my-codex" \
       "$HOME/.local/lib/node_modules/oh-my-codex" \
       "$HOME/.local/share/pnpm/global/5/node_modules/oh-my-codex"
@@ -65,7 +63,7 @@ let
     done
 
     echo "omx is not installed in a known global node location." >&2
-    echo "Expected oh-my-codex under npm global packages, /opt/homebrew, or /opt/zerobrew." >&2
+    echo "Expected oh-my-codex under npm global packages or /opt/zerobrew." >&2
     exit 127
   '';
   omcLauncher = writeShellScriptBin "omc" ''
@@ -113,114 +111,6 @@ let
       oh-my-codex@0.15.0 \
       oh-my-claude-sisyphus@4.13.3
   '';
-  brewPinUpdate = writeShellScriptBin "brew-pin-update" ''
-    set -euo pipefail
-
-    usage() {
-      cat <<'EOF'
-Usage: brew-pin-update [--formula] [--reinstall] <package> [package...]
-
-Update this repo's nix-homebrew pin(s), rebuild the Darwin config, then upgrade
-the requested Homebrew package(s).
-
-Defaults to casks. Use --formula for Homebrew formulae.
-
-Examples:
-  brew-pin-update codex
-  brew-pin-update claude-code
-  brew-pin-update --reinstall codex
-  brew-pin-update --formula ripgrep
-EOF
-    }
-
-    if [ "$(uname)" != "Darwin" ]; then
-      echo "brew-pin-update only supports Darwin hosts managed by nix-homebrew." >&2
-      exit 1
-    fi
-
-    repo_root="$PWD"
-    if [ ! -f "$repo_root/flake.nix" ]; then
-      if repo_root="$(${git}/bin/git rev-parse --show-toplevel 2>/dev/null)"; then
-        :
-      else
-        echo "brew-pin-update must run from this repo or a git worktree inside it." >&2
-        exit 1
-      fi
-    fi
-
-    reinstall=0
-    package_mode="cask"
-
-    while [ "$#" -gt 0 ]; do
-      case "$1" in
-        --formula)
-          package_mode="formula"
-          shift
-          ;;
-        --cask)
-          package_mode="cask"
-          shift
-          ;;
-        --reinstall)
-          reinstall=1
-          shift
-          ;;
-        --help|-h)
-          usage
-          exit 0
-          ;;
-        --)
-          shift
-          break
-          ;;
-        -*)
-          echo "Unknown option: $1" >&2
-          usage >&2
-          exit 2
-          ;;
-        *)
-          break
-          ;;
-      esac
-    done
-
-    if [ "$#" -eq 0 ]; then
-      echo "brew-pin-update: missing package name" >&2
-      usage >&2
-      exit 2
-    fi
-
-    cd "$repo_root"
-
-    if [ "$package_mode" = "cask" ]; then
-      echo "Updating pinned Homebrew cask input..."
-      ${nix}/bin/nix flake lock --update-input homebrew-cask
-    else
-      echo "Updating pinned Homebrew core input..."
-      ${nix}/bin/nix flake lock --update-input homebrew-core
-    fi
-
-    echo "Rebuilding nix-darwin configuration..."
-    ${nix}/bin/nix run .#build-switch
-
-    if [ "$package_mode" = "cask" ]; then
-      if [ "$reinstall" -eq 1 ]; then
-        echo "Reinstalling Homebrew cask(s): $*"
-        /opt/homebrew/bin/brew reinstall --cask "$@"
-      else
-        echo "Upgrading Homebrew cask(s): $*"
-        /opt/homebrew/bin/brew upgrade --cask "$@"
-      fi
-    else
-      if [ "$reinstall" -eq 1 ]; then
-        echo "Reinstalling Homebrew formula(e): $*"
-        /opt/homebrew/bin/brew reinstall "$@"
-      else
-        echo "Upgrading Homebrew formula(e): $*"
-        /opt/homebrew/bin/brew upgrade "$@"
-      fi
-    fi
-  '';
   nixpkgsSearch = writeShellScriptBin "nixpkgs-search" ''
     set -euo pipefail
 
@@ -315,6 +205,7 @@ EOF
 in [
   # General packages for development and system management
   alacritty
+  ast-grep
   bash-completion
   bat
   bear
@@ -355,7 +246,6 @@ in [
   nodejs_24
 
   # Text and terminal utilities
-  brewPinUpdate
   htop
   jetbrains-mono
   jq
@@ -381,6 +271,7 @@ in [
   claude-code
   codex
   lazygit
+  mcp-nixos
   fzf
   direnv
   flyctl
