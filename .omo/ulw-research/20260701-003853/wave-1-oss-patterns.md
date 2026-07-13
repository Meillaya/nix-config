# Wave 1: OSS flake/package update patterns

Worker: Noether (`019f1bf9-7843-7090-909f-f5720d81f2d2`)

## Key findings
- Dominant patterns:
  1. Per-package update scripts for in-repo derivations.
  2. `nvfetcher` generated source expressions for broad source regeneration.
  3. `npins` for non-flake/hybrid dependency pinning.
  4. Native flake lock updates for flake inputs.
  5. Binary artifact overlays use fixed-hash fetch plus package-local update script.
- Real-world binary overlay examples:
  - AppImage: `fufexan/nix-gaming` uses `fetchurl`, `appimageTools`, and `passthru.updateScript = ./update.sh`.
  - DMG: `Reginleif88/claude-cowork-nix` documents daily CI version/hash PRs for a DMG package.
- `npins` alone does not handle artifact extraction/wrapping.
- `nvfetcher` alone does not replace complex package logic for DMGs/AppImages.
- No single maintained repo combines every possible tool; real repos layer mechanisms by source type.

## Sources returned
- Nix flake update manual: https://nix.dev/manual/nix/2.25/command-ref/new-cli/nix3-flake-update
- nvfetcher: https://github.com/berberman/nvfetcher
- npins: https://github.com/andir/npins
- 0xB10C/nix update-packages: https://github.com/0xB10C/nix/blob/master/update-packages.sh
- berberman/flakes Update.hs: https://github.com/berberman/flakes/blob/master/Update.hs
- fufexan/nix-gaming osu-lazer-bin: https://github.com/fufexan/nix-gaming/blob/master/pkgs/osu-lazer-bin/default.nix
- fufexan/nix-gaming update.sh: https://github.com/fufexan/nix-gaming/blob/master/pkgs/osu-lazer-bin/update.sh
- Reginleif88/claude-cowork-nix: https://github.com/Reginleif88/claude-cowork-nix

## EXPAND markers verbatim
- none supplied as actionable leads; worker ended with EXPAND tail heading only.
