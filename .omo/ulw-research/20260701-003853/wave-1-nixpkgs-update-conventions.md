# Wave 1: nixpkgs update conventions

Worker: Ampere (`019f1bf9-70fe-7250-a0aa-e6773acb9665`)

## Key findings
- Idiomatic package shape: `pname`, `version`, fixed-output `src` with `hash`, `passthru` before `meta`, `meta` last.
- Package updates and flake input updates are distinct: `passthru.updateScript` is package-maintenance hook; `flake.lock` is flake dependency lock.
- Prefer `passthru.updateScript = nix-update-script { };` where the update is mechanical.
- Use a custom package-specific update script when there are multiple hashes, nonstandard version discovery, custom version parsing, or extra assets.
- `maintainers/scripts/update.nix` discovers and runs `passthru.updateScript`; scripts should not self-commit.
- `update-source-version` is the low-level helper to rewrite version/source fields.

## Sources returned
- Nixpkgs Reference Manual: https://nixos.org/nixpkgs/manual/
- Nixpkgs package contributor guide: https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md
- NixOS Wiki automatic updates: https://wiki.nixos.org/wiki/Nixpkgs/Automatic_Updates
- Nix flake update reference: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake-update.html
- Nix flake reference: https://releases.nixos.org/nix/nix-2.26.0/manual/command-ref/new-cli/nix3-flake.html
- update.nix: https://raw.githubusercontent.com/NixOS/nixpkgs/master/maintainers/scripts/update.nix
- update-source-version: https://github.com/NixOS/nixpkgs/blob/master/pkgs/common-updater/scripts/update-source-version

## EXPAND markers verbatim
- none supplied as actionable leads; worker ended with EXPAND tail heading only.
