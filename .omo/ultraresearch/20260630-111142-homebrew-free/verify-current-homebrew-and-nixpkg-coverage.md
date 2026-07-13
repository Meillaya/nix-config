# Verification: current repo/Homebrew state and Nix package coverage

## Commands executed
- `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.enable --json`
- `nix eval .#darwinConfigurations.aarch64-darwin.config.nix-homebrew.enable --json`
- `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.casks --json`
- `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.brews --json`
- `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.masApps --json`
- `brew list --cask`, `brew leaves`, `brew services list`
- `nix run .#search-pkgs -- <name>` for cask and mcp-nixos candidates
- `nix eval nixpkgs#legacyPackages.aarch64-darwin.<attr>.meta --json` for candidate replacements

## Output summary
- Repo eval: `homebrew.enable = true`; `nix-homebrew.enable = true`.
- Repo eval active casks: claude-code, codex, iterm2, postman, raycast, obsidian, helium-browser, vesktop, barutsrb/tap/omniwm, zed, stremio, sublime-text.
- Repo eval active brews: `[]`.
- Repo eval active MAS apps: `{}`.
- Machine Homebrew casks currently observed: claude-code, codex, font-jetbrains-mono-nerd-font, font-symbols-only-nerd-font, ghostty, helium-browser, iterm2, obsidian, omniwm, postman, raycast, stremio, sublime-text, vesktop, zed.
- Machine Homebrew leaves currently observed: ast-grep, cocoapods, gh, go, helix, micro, neovim, omniorb, python@3.12, uv, zig.
- Nix package coverage verified on `aarch64-darwin`: claude-code, codex, iterm2, postman, raycast, obsidian, vesktop, zed-editor, jetbrains-mono, nerd-fonts.jetbrains-mono, mcp-nixos, cocoapods, dockutil, helix, micro, neovim, omniorb, uv, ast-grep, gh, go, python312, zig.
- No good nixpkgs attr found for active casks: helium-browser, omniwm, sublime-text on Darwin.
- `ghostty` metadata in this pinned nixpkgs reported Linux platforms only.
- `stremio` eval on unstable reported removal due vulnerable/outdated qt5 webengine; stable search still showed a stremio attr, but this repo follows nixos-unstable so treat Stremio as not safely available from current nixpkgs.

## Verdict
CONFIRMED: most casks/formula leaves can be replaced with Nix packages; a few app gaps require non-Homebrew alternatives, packaging, or manual installation outside Homebrew.
