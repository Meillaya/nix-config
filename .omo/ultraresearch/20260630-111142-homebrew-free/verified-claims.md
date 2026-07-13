# Verified Claims Digest

- Repo state: `homebrew.enable = true`, `nix-homebrew.enable = true`, 12 casks, no brews, no MAS apps (`verify-current-homebrew-and-nixpkg-coverage.md`).
- Current machine state includes extra Homebrew-managed items not declared in repo: fonts, Ghostty, and formula leaves including ast-grep/gh/go/python@3.12/zig (`verify-current-homebrew-and-nixpkg-coverage.md`).
- nix-darwin Homebrew is Brewfile orchestration only and requires Homebrew to already exist (upstream nix-darwin source cited in wave journals).
- Homebrew-free GUI apps should move to Nix packages exposed by nix-darwin `/Applications/Nix Apps` or Home Manager Darwin app targets (upstream nix-darwin/Home Manager sources cited in wave journals).
- App data preservation requires avoiding cask `zap`; uninstall should be inventory-first with official Homebrew uninstall script after Nix replacements work (Homebrew docs cited in wave journals).
- mcp-nixos is a valid Nix-managed lookup helper if you want an MCP-backed package/options search path without Homebrew (user-provided repo + local Nix search).
