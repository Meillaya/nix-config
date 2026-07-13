# Wave 2: Strict no-Homebrew paths for remaining app gaps

## Findings
- Helium Browser has official GitHub macOS releases and a `helium-macos` repo with DMG assets; strict no-Homebrew path is local Nix binary-app derivation or manual vendor install. Sources: https://github.com/imputnet/helium, https://github.com/imputnet/helium-macos/releases, https://helium.computer/
- OmniWM has official GitHub releases and docs; strict no-Homebrew path is local Nix binary-app derivation from upstream release, or switch to nixpkgs alternatives such as AeroSpace/yabai/skhd. Sources: https://github.com/BarutSRB/OmniWM, https://github.com/BarutSRB/OmniWM/releases, https://barutsrb.github.io/OmniWM/
- Stremio has official macOS downloads; current nixpkgs unstable Stremio is not a safe Darwin replacement in local eval. Strict no-Homebrew path is vendor DMG/manual install or a local binary derivation if redistribution/license permits. Sources: https://www.stremio.com/downloads, https://blog.stremio.com/stremio-on-macos-issues-are-now-resolved/
- Sublime Text has official macOS downloads and license terms; local nixpkgs attrs evaluated as Linux-only for this snapshot. Strict no-Homebrew path is vendor DMG/manual install, local derivation if allowed, or replace with Zed/Helix/Neovim already in Nix. Sources: https://www.sublimetext.com/download, https://www.sublimetext.com/
- Ghostty is not an active repo cask but is installed on the machine through Homebrew. This repo already ships Alacritty via Nix and fastfetch has Ghostty-specific config, so strict no-Homebrew options are: use Alacritty/iTerm2 from Nix, or package/install Ghostty outside Homebrew after verifying current Darwin package status.

## EXPAND
- LEAD: local binary derivation templates for DMG apps — WHY: strict no-Homebrew while preserving Helium/OmniWM/Stremio/Sublime may require local packaging — ANGLE: inspect nixpkgs `undmg`/`copy .app to $out/Applications` patterns and licenses for each upstream.
- LEAD: runtime app QA — WHY: vendor-signed app bundles may require Gatekeeper/accessibility/login item checks after Nix packaging — ANGLE: build local derivation and launch each app on macOS.
