# Wave 1: Codebase repo Homebrew surface

Worker: explorer `019f1916-7646-7471-bc81-7b905dbb425e`

## Key findings
- Current Homebrew wiring is in `flake.nix`, `modules/darwin/home-manager.nix`, and `modules/darwin/casks.nix`.
- Top-level inputs include `nix-homebrew`, `homebrew-bundle`, `homebrew-core`, `homebrew-cask`, and `barutsrb-homebrew-tap`.
- Darwin configuration imports `nix-homebrew.darwinModules.nix-homebrew`, enables it, pins four taps, sets `mutableTaps = false`, and `autoMigrate = true`.
- Active nix-darwin Homebrew payload: 12 casks (`claude-code`, `codex`, `iterm2`, `postman`, `raycast`, `obsidian`, `helium-browser`, `vesktop`, `barutsrb/tap/omniwm`, `zed`, `stremio`, `sublime-text`), no active formulae, no active MAS apps.
- Separate Homebrew assumptions remain in shell PATH setup and `brew-pin-update` helper.
- History shows earlier casks already removed: Docker cask, VS Code, Cursor, Google Chrome, Steam.

## Source/file anchors
- `/Users/mei/nixos-config/flake.nix:11`
- `/Users/mei/nixos-config/flake.nix:395`
- `/Users/mei/nixos-config/modules/darwin/home-manager.nix:20`
- `/Users/mei/nixos-config/modules/darwin/casks.nix:3`
- `/Users/mei/nixos-config/modules/shared/home-manager.nix:97`
- `/Users/mei/nixos-config/modules/shared/home-manager.nix:195`
- `/Users/mei/nixos-config/modules/shared/home-manager.nix:318`
- `/Users/mei/nixos-config/modules/shared/packages.nix:13`
- `/Users/mei/nixos-config/modules/shared/packages.nix:41`
- `/Users/mei/nixos-config/modules/shared/packages.nix:116`
- `/Users/mei/nixos-config/docs/service-notes/nix-homebrew.md:1`

## EXPAND markers verbatim
- LEAD: nix-homebrew flake wiring — WHY: this is the top-level activation point for all Darwin Homebrew behavior — ANGLE: inspect `flake.nix` plus `flake.lock` for tap/input ownership and how disabling/removing `nix-homebrew` would cascade
- LEAD: Darwin cask inventory — WHY: these are the concrete user-visible apps Homebrew currently installs — ANGLE: compare `modules/darwin/casks.nix` to the latest commit history to identify which casks were removed and which remain
- LEAD: `/opt/homebrew` path entanglement — WHY: shell startup and helper scripts still assume a Homebrew prefix even outside explicit Homebrew config — ANGLE: trace every `/opt/homebrew` reference in `modules/shared/home-manager.nix` and `modules/shared/packages.nix`
- LEAD: Homebrew update workflow — WHY: `brew-pin-update` is the repo’s operational mechanism for Homebrew changes — ANGLE: inspect `modules/shared/packages.nix` and `docs/service-notes/nix-homebrew.md` for how updates, reinstall/upgrade, and formula-vs-cask flows are expected to work
- LEAD: historical removal trail — WHY: commit history shows what Homebrew surface was pruned already versus what is still active — ANGLE: review `8bcdb68`, `99641d0`, and `af306e4` for deleted casks, Darwin launch changes, and initial Homebrew integration
