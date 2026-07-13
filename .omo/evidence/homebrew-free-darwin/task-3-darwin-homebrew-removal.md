# Task 3 Darwin Homebrew/cask removal evidence

## casks file removed
modules/darwin/casks.nix removed

## Darwin/docs scan

## diff
diff --git a/docs/service-notes/nix-homebrew.md b/docs/service-notes/nix-homebrew.md
deleted file mode 100644
index 40ac66f..0000000
--- a/docs/service-notes/nix-homebrew.md
+++ /dev/null
@@ -1,22 +0,0 @@
-# nix-homebrew update workflow
-
-On Darwin, Homebrew is pinned and managed by `nix-homebrew`, so `brew update`
-is expected to fail when it tries to mutate tap repos inside `/nix/store`.
-
-Use the repo helper instead:
-
-```bash
-brew-pin-update codex
-brew-pin-update claude-code
-brew-pin-update --reinstall codex
-brew-pin-update --formula ripgrep
-```
-
-What it does:
-
-1. updates the relevant flake input (`homebrew-cask` by default, or
-   `homebrew-core` with `--formula`)
-2. runs `nix run .#build-switch`
-3. upgrades or reinstalls the requested Homebrew package
-
-This keeps Homebrew package updates aligned with the repo's pinned tap state.
diff --git a/modules/darwin/README.md b/modules/darwin/README.md
index 90ab44e..5c44117 100644
--- a/modules/darwin/README.md
+++ b/modules/darwin/README.md
@@ -3,9 +3,8 @@
 ```
 .
 ├── dock               # MacOS dock configuration
-├── casks.nix          # List of homebrew casks
 ├── default.nix        # Defines module, system-level config
 ├── files.nix          # Non-Nix, static configuration files (now immutable!)
 ├── home-manager.nix   # Defines user programs
-├── packages.nix       # List of packages to install for MacOS
+├── packages.nix       # List of Nix packages to install for MacOS
 ```
diff --git a/modules/darwin/casks.nix b/modules/darwin/casks.nix
deleted file mode 100644
index 6a9fc6e..0000000
--- a/modules/darwin/casks.nix
+++ /dev/null
@@ -1,29 +0,0 @@
-_:
-
-[
-  # Development Tools
-  "claude-code"
-  "codex"
-  "iterm2"
-  "postman"
-
-  # Productivity Tools
-  "raycast"
-  "obsidian"
-
-  # Browsers
-  "helium-browser"
-
-  # Communication Tools
-  "vesktop"
-
-  # Utility Tools
-  "barutsrb/tap/omniwm"
-  "zed"
-
-  # Entertainment Tools
-  "stremio"
-
-  # Writing / notes
-  "sublime-text"
-]
diff --git a/modules/darwin/home-manager.nix b/modules/darwin/home-manager.nix
index 0d694d3..9ffe60f 100644
--- a/modules/darwin/home-manager.nix
+++ b/modules/darwin/home-manager.nix
@@ -17,28 +17,6 @@ in
     shell = pkgs.zsh;
   };
 
-  homebrew = {
-    enable = true;
-    taps = builtins.attrNames config.nix-homebrew.taps;
-    casks = pkgs.callPackage ./casks.nix {};
-    # onActivation.cleanup = "uninstall";
-
-    # These app IDs are from using the mas CLI app
-    # mas = mac app store
-    # https://github.com/mas-cli/mas
-    #
-    # $ nix shell nixpkgs#mas
-    # $ mas search <app name>
-    #
-    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
-    # you may receive an error message "Redownload Unavailable with This Apple ID".
-    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
-
-    masApps = {
-      # "wireguard" = 1451685025;
-    };
-  };
-
   # Enable home-manager
   home-manager = {
     useGlobalPkgs = true;
