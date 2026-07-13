# Wave 2: Local implementation shape for Homebrew-free Darwin config

## Minimal repo change surface
- `flake.nix`: remove inputs `nix-homebrew`, `homebrew-bundle`, `homebrew-core`, `homebrew-cask`, `barutsrb-homebrew-tap`; remove them from `outputs` argument set; remove `nix-homebrew.darwinModules.nix-homebrew` and the inline `nix-homebrew = { ... };` module from `darwinConfigurations`.
- `modules/darwin/home-manager.nix`: delete the `homebrew = { ... };` block entirely; optionally update Dock entries for Nix app paths if replacing casks.
- `modules/darwin/casks.nix`: delete after all cask references are gone, or leave unused only temporarily; strict cleanup should delete/update README.
- `modules/darwin/README.md`: remove `casks.nix` Homebrew description and replace with Nix app/package guidance.
- `modules/shared/home-manager.nix`: remove `/opt/homebrew/bin` and `/opt/homebrew/sbin` PATH prepends from bash/fish/zsh init.
- `modules/shared/packages.nix`: remove `brewPinUpdate`; remove `/opt/homebrew` from `omxLauncher` search candidates/error text unless intentionally kept as legacy fallback; add any Nix replacements not already present.
- `docs/service-notes/nix-homebrew.md`: delete or replace with a migration note; strict no-Homebrew means this workflow should disappear.
- `flake.lock`: will drop Homebrew/nix-homebrew inputs after `nix flake lock`/`nix flake update --commit-lock-file` equivalent.

## Replacements already present
- Shared package list already includes `claude-code`, `codex`, `zed-editor`, `gh`, `go`, `python3`, `zig`, `uv`, `helix`, `micro`, `neovim`, `ast-grep` equivalent? `ast-grep` is not currently visible in shared list, but `sg` skill exists externally; add `ast-grep` if needed.
- Darwin packages already include `cocoapods`, `dockutil`, `omniorb`, `uv`, plus shared packages.
- Dock currently points to Nix Alacritty, not iTerm2/Ghostty.

## Verification commands
- `rg -n "homebrew|brew|cask|masApps|/opt/homebrew|nix-homebrew|brew-pin-update" . --glob '!flake.lock'`
- `nix flake check` or at least `nix eval .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath`
- `nix run .#build` / `nix run .#build-switch` on Darwin only after review.
- After switch: `command -v brew` should fail once uninstall is complete; `/Applications/Nix Apps` should contain Nix-packaged apps.

## EXPAND
- LEAD: exact patch implementation — WHY: code changes are mechanical but broad across flake/modules/docs — ANGLE: apply in a separate implementation pass after user accepts app-gap decisions.
- LEAD: lockfile cleanup — WHY: removing inputs requires regenerating `flake.lock` and can touch many lines — ANGLE: run `nix flake lock` after editing flake inputs.
