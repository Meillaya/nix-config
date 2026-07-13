# Claim Ledger

| Claim | Risk | Domains / artifacts | Counter-search / proof | Primary? | Status |
|---|---:|---|---|---|---|
| Current repo enables both nix-darwin Homebrew integration and nix-homebrew. | normal | local `nix eval`; `flake.nix`; `modules/darwin/home-manager.nix` | `nix eval` output true/true | local config | verified |
| Current repo Homebrew payload is 12 casks, no brews, no MAS apps. | normal | local `nix eval`; `modules/darwin/casks.nix` | `nix eval homebrew.casks/brews/masApps` | local config | verified |
| Machine has additional unmanaged Homebrew casks/formula leaves beyond repo config. | normal | local `brew list --cask`; `brew leaves` | command output captured in verification artifact | local machine | verified |
| nix-darwin Homebrew module does not install Homebrew and requires a preexisting brew binary when enabled. | high | nix-darwin source/docs; worker citations | source check in `modules/homebrew.nix` and `modules/system/checks.nix` | upstream source | verified |
| nix-darwin can expose Nix-packaged `.app` bundles without Homebrew through `/Applications/Nix Apps`. | high | nix-darwin source; real-world repo examples | source `system/applications.nix`; public configs | upstream source | verified |
| Home Manager can also expose Darwin apps from `home.packages`, but app-management/path caveats exist. | high | Home Manager source; HM issue #3557 | source `linkapps.nix`/`copyapps.nix`; issue counterexample | upstream source | verified |
| Avoid cask `zap` when preserving app data. | high | Homebrew Cask Cookbook; uninstall research | counter-search found `zap` removes preferences/caches/shared resources | official docs | verified |
| Most active casks and all observed brew leaves have Nix replacements on aarch64-darwin. | normal | local `nix search`; `nix eval meta`; verification artifact | explicit eval/search list | local Nix execution | verified |
| `helium-browser`, `omniwm`, Darwin `sublime-text`, current `ghostty`, and current `stremio` are gaps in the pinned Nix replacement set. | normal | local `nix search`; `nix eval meta`; verification artifact | failed/no-match/eval outputs | local Nix execution | verified |
| mcp-nixos is available as a Nix-managed package on aarch64-darwin and can be used for Nix package/options lookup. | normal | user-provided GitHub repo; local `nix search` | cloned repo HEAD and search output | GitHub + local Nix | verified |
