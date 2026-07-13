# Ultraresearch Synthesis: Remove Homebrew from this nix-darwin Mac

Workers: 9 · Waves: 2 · Verification artifacts: 3 · Access date: 2026-06-30

## Executive summary

The repo is still actively Homebrew-managed on Darwin: `flake.nix` wires `nix-homebrew` plus pinned Homebrew taps, `modules/darwin/home-manager.nix` enables `homebrew`, and `modules/darwin/casks.nix` declares 12 casks; local `nix eval` confirmed `homebrew.enable = true`, `nix-homebrew.enable = true`, 12 casks, no Homebrew formulae, and no active MAS apps [Local 1]. nix-darwin’s Homebrew module is only a `brew bundle` integration and does not install Homebrew; upstream source/docs say it requires a preexisting `brew` when enabled [Source 1][Source 2].

A strict Homebrew-free target is feasible, but not every current app has a direct nixpkgs Darwin package. Most CLI tools and most casks are replaceable with Nix packages now; the remaining app gaps (`helium-browser`, `omniwm`, `stremio`, `sublime-text`) need local binary packaging, a third-party flake, a vendor/manual install outside Homebrew, or an alternative app [Local 2]. GUI app success must be verified on macOS, because nix-darwin/Home Manager copy apps into Nix-owned Applications folders and macOS Spotlight, LaunchServices, App Management permissions, and Dock aliases can lag or break per app [Source 3][Source 4][Source 5].

## Findings by theme

### Current repo Homebrew surface

- `flake.nix` declares `nix-homebrew`, `homebrew-bundle`, `homebrew-core`, `homebrew-cask`, and `barutsrb-homebrew-tap`; Darwin systems import `nix-homebrew.darwinModules.nix-homebrew` and pin four taps [Local 3].
- `modules/darwin/home-manager.nix` sets `homebrew.enable = true`, derives taps from `config.nix-homebrew.taps`, loads casks from `modules/darwin/casks.nix`, and has an empty `masApps` map [Local 3].
- `modules/shared/home-manager.nix` still prepends `/opt/homebrew/bin` and `/opt/homebrew/sbin` in bash, fish, and zsh startup; `modules/shared/packages.nix` ships `brew-pin-update`, a helper that updates pinned Homebrew tap inputs and shells out to `/opt/homebrew/bin/brew` [Local 3].
- Current machine state has extra Homebrew-managed items not declared in the repo: casks for fonts and Ghostty, plus formula leaves such as `ast-grep`, `gh`, `go`, `python@3.12`, and `zig` [Local 1].

### What Nix can replace immediately

- Direct nixpkgs Darwin replacements exist for `claude-code`, `codex`, `iterm2`, `postman`, `raycast`, `obsidian`, `vesktop`, and `zed` via `zed-editor` [Local 1].
- Current observed Homebrew formula leaves are all Nix-replaceable: `cocoapods`, `gh`, `go`, `helix`, `micro`, `neovim`, `omniorb`, `python3`, `uv`, `zig`, and `ast-grep`; most are already in the repo’s package lists except `ast-grep` [Local 1][Local 4].
- Fonts should move to Nix font packages, especially `jetbrains-mono` and `nerd-fonts.jetbrains-mono`; the repo already includes JetBrains Mono and other Nix fonts [Local 1][Local 4].
- The user-provided `utensils/mcp-nixos` lead is valid for this migration: its README says it queries NixOS packages/options, Home Manager, and nix-darwin data, and local Nix search confirmed `mcp-nixos` is available on `aarch64-darwin` [Source 6][Local 1].

### Remaining strict-no-Homebrew app gaps

| App | Best Homebrew-free path | Evidence |
|---|---|---|
| Helium Browser | Use/vendor `schembriaiden/helium-browser-nix-flake`, or package official `imputnet/helium-macos` DMG locally | Official Helium macOS releases include arm64/x86_64 DMGs; worker found a Darwin-supporting Nix flake [Source 7][Source 8]. |
| OmniWM | Package official release ZIP locally, or replace with `aerospace`/`yabai`/`skhd` | Official release publishes `OmniWM-v0.5.2.1.zip`; no nixpkgs `omniwm` attr was found [Source 9][Local 2]. |
| Stremio | Vendor/manual install or local binary derivation from official macOS DMG; source-native Darwin packaging is unclear | Official downloads expose macOS DMGs; local nixpkgs eval found current unstable Stremio unsuitable for Darwin [Source 10][Local 1]. |
| Sublime Text | Vendor/manual install or local unfree binary derivation from official macOS ZIP; or replace with Zed/Helix/Neovim | Official macOS ZIP exists; nixpkgs Sublime attrs evaluated Linux-only in this snapshot [Source 11][Local 1]. |
| Ghostty | Add `ghostty-bin` if available in this pin/overlay; otherwise use Nix Alacritty/iTerm2 until pin catches up | Current nixpkgs has a Darwin binary package per worker; repo pin needs verification before implementation [Source 12][Local 2]. |

### nix-darwin and Home Manager app mechanics

- nix-darwin exposes Nix-packaged `.app` bundles by building from `environment.systemPackages` and copying linked apps into `/Applications/Nix Apps` [Source 3].
- Home Manager also has Darwin app placement from `home.packages`; current upstream has copy/link modes with App Management permission checks, and behavior depends on Home Manager state/version [Source 4][Source 5].
- Apple documents Spotlight and LaunchServices around Applications folders, app metadata, aliases, and privacy permissions; Dock items can keep old cask-path aliases, so migrated apps should be launched/repinned from the Nix-owned bundle path [Source 13][Source 14][Source 15][Source 16].

## Recommended migration plan

1. **Patch repo config to stop declaring Homebrew**: remove Homebrew/nix-homebrew inputs and Darwin module wiring from `flake.nix`; delete the `homebrew = { ... };` block from `modules/darwin/home-manager.nix`; retire `modules/darwin/casks.nix`; remove `brewPinUpdate`; remove `/opt/homebrew` PATH prepends; update/delete Homebrew docs [Local 5].
2. **Keep/add Nix replacements**: keep existing `claude-code`, `codex`, `zed-editor`, `gh`, `go`, `python3`, `zig`, `uv`, `helix`, `micro`, `neovim`, `cocoapods`; add `ast-grep`; optionally add `mcp-nixos`, `ghostty-bin`, and `aerospace` if you want those exact capabilities [Local 1][Local 4].
3. **Choose gap policy**: for strict zero Homebrew, do not keep casks. Either vendor/package Helium, OmniWM, Stremio, and Sublime locally, replace them, or install vendor apps manually outside Homebrew [Local 2].
4. **Build and switch**: verify no active Homebrew references remain, build the Darwin system, then switch from a graphical terminal with App Management permission if apps are copied into `/Applications/Nix Apps` [Source 3][Source 16].
5. **Only after Nix replacements work, uninstall Homebrew**: inventory with `brew list --cask`, `brew leaves --installed-on-request`, `brew services list`, and optional `brew bundle dump`; avoid `--zap` if preserving app data; run the official Homebrew uninstall script for the correct prefix (`/opt/homebrew` on Apple Silicon, `/usr/local` for Intel/old dual-prefix installs) [Source 17][Source 18][Source 19].
6. **Post-switch QA**: confirm app bundles exist in `/Applications/Nix Apps` or Home Manager’s app folder, verify Spotlight via `mdfind`, open each app from its new path, grant Accessibility/App Management where needed, and repin Dock aliases [Source 13][Source 14][Source 16].

## Verification commands

```bash
# Config should not actively reference Homebrew after patching
rg -n --hidden -e 'nix-homebrew|homebrew|Homebrew|brew-pin-update|/opt/homebrew' . --glob '!flake.lock'

# Build/eval checks
nix eval .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath
nix build .#darwinConfigurations.aarch64-darwin.system --no-link

# Current machine inventory before uninstalling Homebrew
brew list --cask
brew leaves --installed-on-request
brew services list
brew bundle dump --file "$HOME/Desktop/Brewfile.before-nix-only" --force

# Post-switch app checks
find /Applications/Nix\ Apps -maxdepth 1 -name '*.app' -type d
mdls -name kMDItemCFBundleIdentifier "/Applications/Nix Apps/Foo.app"
mdfind 'kMDItemCFBundleIdentifier == "com.vendor.App"'
open "/Applications/Nix Apps/Foo.app"
```

## Contradictions resolved

- nix-darwin’s Homebrew activation script contains a “skip if missing” branch, but source-level checks can abort earlier when `homebrew.enable` is true and `brew` is missing; treat enabled Homebrew as requiring a preexisting Homebrew install [Source 1][Source 2].
- `nix search` can show packages that are not valid Darwin replacements; `stremio` and `sublime*` needed metadata/platform evaluation, which refuted them as safe Darwin replacements in this repo’s current snapshot [Local 1].

## Gaps and remaining risks

- No code was changed in this research pass; implementation and lockfile cleanup remain future work.
- Local binary packaging for Helium/OmniWM/Stremio/Sublime needs license/hash/runtime validation before adding to this repo.
- macOS GUI behavior remains partly runtime-specific: App Management permission, Spotlight indexing, Dock aliases, Accessibility grants, and path-sensitive apps must be tested on the target Mac after switching.

## Sources

- [Local 1] `.omo/ultraresearch/20260630-111142-homebrew-free/verify-current-homebrew-and-nixpkg-coverage.md`
- [Local 2] `.omo/ultraresearch/20260630-111142-homebrew-free/wave-2-web-strict-gap-paths-worker.md`
- [Local 3] `.omo/ultraresearch/20260630-111142-homebrew-free/wave-1-codebase-repo-homebrew-surface.md`
- [Local 4] `.omo/ultraresearch/20260630-111142-homebrew-free/wave-2-codebase-implementation-shape-local.md`
- [Local 5] `.omo/ultraresearch/20260630-111142-homebrew-free/wave-2-codebase-implementation-shape-local.md`
- [Source 1] https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/homebrew.nix
- [Source 2] https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/checks.nix
- [Source 3] https://github.com/LnL7/nix-darwin/blob/a1fa429e945becaf60468600daf649be4ba0350c/modules/system/applications.nix
- [Source 4] https://github.com/nix-community/home-manager/blob/5d72a29fc36ac21adae6ae35568fe5ee6700850f/modules/targets/darwin/linkapps.nix
- [Source 5] https://github.com/nix-community/home-manager/blob/5d72a29fc36ac21adae6ae35568fe5ee6700850f/modules/targets/darwin/copyapps.nix
- [Source 6] https://github.com/utensils/mcp-nixos
- [Source 7] https://github.com/imputnet/helium-macos/releases/latest
- [Source 8] https://github.com/schembriaiden/helium-browser-nix-flake
- [Source 9] https://github.com/BarutSRB/OmniWM/releases
- [Source 10] https://www.stremio.com/downloads
- [Source 11] https://www.sublimetext.com/download
- [Source 12] https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/gh/ghostty-bin/package.nix
- [Source 13] https://support.apple.com/guide/mac-help/open-apps-in-spotlight-mh35840/mac
- [Source 14] https://support.apple.com/guide/mac-help/create-and-remove-aliases-on-mac-mchlp1046/mac
- [Source 15] https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/LaunchServicesConcepts/LSCConcepts/LSCConcepts.html
- [Source 16] https://support.apple.com/guide/mac-help/change-privacy-security-settings-on-mac-mchl211c911f/mac
- [Source 17] https://github.com/Homebrew/install/blob/main/README.md
- [Source 18] https://docs.brew.sh/Manpage
- [Source 19] https://docs.brew.sh/Cask-Cookbook
