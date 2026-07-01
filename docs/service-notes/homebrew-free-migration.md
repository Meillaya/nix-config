# Homebrew-free Darwin migration

This repo is intended to manage the Darwin system with Nix, not Homebrew.
Use `mcp-nixos` and the unstable package index at
<https://search.nixos.org/packages?channel=unstable> for package lookup and
verification before adding new Darwin packages.

## Package lookup

`mcp-nixos` is installed by this config. For agent verification, use its NixOS
package search on the `unstable` channel before relying on a package name.
The package index URL above is the human-facing reference for the same channel.

## Before removing the existing Homebrew installation

Only remove the physical Homebrew tree after the Nix config has built, switched,
and the replacement apps work from their Nix-owned paths.

Read-only inventory commands:

```bash
brew list --cask
brew leaves --installed-on-request
brew services list
brew bundle dump --file "$HOME/Desktop/Brewfile.before-nix-only" --force
```

Do not use cask `zap` if preserving app data. Prefer the official uninstall
script only after inventory and replacement QA are complete.

## Post-switch app checks

```bash
find /Applications/Nix\ Apps -maxdepth 1 -name '*.app' -type d
mdls -name kMDItemCFBundleIdentifier "/Applications/Nix Apps/Foo.app"
mdfind 'kMDItemCFBundleIdentifier == "com.vendor.App"'
open "/Applications/Nix Apps/Foo.app"
```

Re-pin Dock aliases from the Nix-owned app bundle paths if macOS keeps pointing
at an old app location.

## Deferred apps

The previous cask set included Helium, OmniWM, Stremio, and Sublime Text. They
are intentionally not reintroduced here until each has a Nix-managed package,
local derivation, or explicit manual-vendor install decision.
