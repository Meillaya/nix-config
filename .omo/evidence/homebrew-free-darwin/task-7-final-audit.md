# Task 7 final migration evidence

## package presence assertions
{"ast-grep":true,"ghostty-bin":true,"iterm2":true,"mcp-nixos":true,"obsidian":true,"postman":true,"raycast":true,"vesktop":true}

## nix-homebrew option absent check
warning: Git tree '/Users/mei/nixos-config' is dirty
error: flake 'git+file:///Users/mei/nixos-config' does not provide attribute 'packages.aarch64-darwin.darwinConfigurations.aarch64-darwin.config.nix-homebrew.enable', 'legacyPackages.aarch64-darwin.darwinConfigurations.aarch64-darwin.config.nix-homebrew.enable' or 'darwinConfigurations.aarch64-darwin.config.nix-homebrew.enable'

## final product scan

## migration doc scan
4:Use `mcp-nixos` and the unstable package index at
5:<https://search.nixos.org/packages?channel=unstable> for package lookup and
10:`mcp-nixos` is installed by this config. For agent verification, use its NixOS
22:brew list --cask
23:brew leaves --installed-on-request
24:brew services list
28:Do not use cask `zap` if preserving app data. Prefer the official uninstall
43:## Deferred apps

## final git status
 D docs/service-notes/nix-homebrew.md
 M flake.lock
 M flake.nix
 M modules/darwin/README.md
 D modules/darwin/casks.nix
 M modules/darwin/home-manager.nix
 M modules/darwin/packages.nix
 M modules/shared/home-manager.nix
 M modules/shared/packages.nix
?? .omc/
?? .omo/
?? docs/service-notes/homebrew-free-migration.md
