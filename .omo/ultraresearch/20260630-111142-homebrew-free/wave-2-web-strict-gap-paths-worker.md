# Wave 2: Strict no-Homebrew paths for remaining app gaps (worker)

Worker: dependency-expert `019f1922-9bf8-7322-bba3-003fa0bde9c6`

## Key findings
- `helium-browser`: best path is `schembriaiden/helium-browser-nix-flake`, or vendor its derivation locally; upstream `imputnet/helium-macos` publishes arm64/x86_64 DMGs.
- `omniwm`: no nixpkgs attr; exact path is local binary packaging from official `OmniWM-v*.zip`; functional alternative is `pkgs.aerospace`.
- `stremio`: no Darwin-native nixpkgs app path; official macOS DMG/manual install/local binary derivation is the strict path, but source-native Darwin packaging is not straightforward.
- `sublime-text`: nixpkgs Sublime is Linux-only; official macOS ZIP can be manual/vendor install or local unfree binary derivation.
- `ghostty`: use `pkgs.ghostty-bin` if available in pin/overlay; source-built `ghostty` remains Linux-only.

## Sources
- https://github.com/imputnet/helium
- https://github.com/imputnet/helium-macos/releases/latest
- https://github.com/schembriaiden/helium-browser-nix-flake
- https://github.com/BarutSRB/OmniWM/releases
- https://github.com/nikitabobko/AeroSpace
- https://www.stremio.com/downloads
- https://github.com/Stremio/stremio-shell
- https://www.sublimetext.com/download
- https://ghostty.org/download
- https://ghostty.org/docs/install/binary
- https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/gh/ghostty-bin/package.nix

## EXPAND
- DEAD END: Direct nixpkgs attrs for Helium/OmniWM/Darwin Sublime — searched; not found as of 2026-06-30.
- DEAD END: Source-native Stremio Darwin desktop package — visible upstream split does not map cleanly to complete desktop app within this pass.
