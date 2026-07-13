# User-provided lead: utensils/mcp-nixos

Repository: https://github.com/utensils/mcp-nixos
Local clone: /tmp/mcp-nixos-research
HEAD: 0ef99b6a5674e60ca315dc55a0f458673bb1e4fa

README findings:
- MCP-NixOS provides MCP tools for NixOS packages, options, Home Manager, nix-darwin, Nixvim, flakes, nix.dev, wiki, NixHub, and cache status.
- It has install paths via `uvx mcp-nixos`, `nix run github:utensils/mcp-nixos --`, Docker, and HTTP transport.
- The README says it can query package versions/historical versions/cache status and local flake inputs when Nix is available.
- This repo's own `nix run .#search-pkgs -- mcp-nixos` found `legacyPackages.aarch64-darwin.mcp-nixos` in nixpkgs unstable and stable, so it can be added as a Nix-managed tool without Homebrew.

EXPAND:
- LEAD: mcp-nixos as verification helper — WHY: user explicitly pointed at it and it can query nix-darwin/options/package data — ANGLE: evaluate whether to add `pkgs.mcp-nixos` to shared/Darwin packages or use via `nix run github:utensils/mcp-nixos --` without permanent config.
