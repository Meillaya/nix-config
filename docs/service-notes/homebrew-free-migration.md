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

## Former cask decisions

No former app cask is deferred. The remaining apps have explicit non-Homebrew
management decisions:

- Helium: local Darwin derivation `helium` in `overlays/20-helium.nix`, sourced from the official `imputnet/helium-macos` DMG release.
- OmniWM: local Darwin derivation `omniwm` in `overlays/20-helium.nix`, sourced from the upstream GitHub release zip and exposing `omniwmctl` through the Nix profile.
- Stremio: local Darwin derivation `stremio` in `overlays/20-helium.nix`, sourced from the official Stremio macOS DMG.
- Sublime Text: local Darwin derivation `sublimeText` in `overlays/20-helium.nix`, sourced from the official Sublime Text macOS zip.

After `nix run .#build-switch`, these app bundles should appear under
`/Applications/Nix Apps` and can be removed from Homebrew with `brew uninstall
--cask` while preserving user data.
