# Wave 1: Upstream nix-darwin/nixpkgs app and Homebrew implementation

Worker: librarian `019f1917-09d0-7e13-ade5-7f64b8487b3f`

## Key findings
- nix-darwin native app activation is independent of Homebrew: `system.build.applications` builds a package environment from `environment.systemPackages` with `/Applications` linked, then activation rsyncs those bundles into `/Applications/Nix Apps`.
- App activation has macOS permission/TCC handling; updating `/Applications/Nix Apps` can fail over SSH or without appropriate app-management/full-disk permissions.
- nix-darwin Homebrew module is a `brew bundle` integration, not a Homebrew installer; enabling it does not install Homebrew and checks abort if `brew` is missing.
- The Homebrew module models casks and MAS apps; MAS removals are not automatically uninstalled even when cleanup is uninstall/zap.
- nixpkgs packages native macOS apps by copying `.app` bundles into `$out/Applications`, often preserving vendor-signed binaries and using wrapper shims where useful.
- `mkAppleDerivation` is not a generic app-bundle packager; it is specialized for Apple source distributions.

## Sources
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/applications.nix#L59-L111
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/checks.nix#L10-L57
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/homebrew.nix#L666-L683
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/checks.nix#L254-L263
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/homebrew.nix#L769-L890
- https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/homebrew.nix#L965-L977
- https://github.com/NixOS/nixpkgs/blob/883ce449b3e1662eef79a92bbfd40f0a5b29e77e/pkgs/by-name/ob/obsidian/package.nix#L148-L154

## EXPAND markers verbatim
- LEAD: nix-darwin activation ordering and privilege boundaries — WHY: to confirm whether app copies run before/after user defaults, launchd, and post-activation hooks — ANGLE: inspect `modules/system/activation-scripts.nix`, `modules/services/activate-system/default.nix`, and any `activate-user` transition code
- LEAD: Homebrew module option surface evolution — WHY: to identify which current options are legacy, renamed, or removed when stripping Homebrew — ANGLE: search `mkRenamedOptionModule` / `mkRemovedOptionModule` history and related PRs/issues in nix-darwin
- LEAD: nixpkgs macOS app bundle packaging patterns — WHY: to catalog the most common bundle recipes for replacing casks with nixpkgs packages — ANGLE: sample more `pkgs/by-name/*/*/package.nix` files that install into `$out/Applications` and expose wrappers
- LEAD: MAS / cask trust and cleanup semantics — WHY: to determine whether any cask/MAS use can be retained without surprising cleanup behavior — ANGLE: inspect Homebrew Bundle upstream behavior for `trusted`, `appdir`, and `cleanup --zap` semantics, then compare to nix-darwin’s generated Brewfile
