# Wave 1: codebase / repo fixed pins

Worker: Explorer (`019f1bf9-75ff-73a0-a2f7-1a1625d8de87`)

## Key findings
- Repo update app exists in `/Users/mei/nixos-config/flake.nix:343-364`; it runs `nix flake update "$@"` and chains Raycast updater on Darwin.
- Raycast updater exists in `/Users/mei/nixos-config/overlays/40-raycast.nix:17-69` and is the only current self-updating repo-local fixed-output pin.
- Manual fixed-output pins remain in:
  - `/Users/mei/nixos-config/overlays/10-feather-font.nix:3-12`
  - `/Users/mei/nixos-config/modules/linux/home-manager.nix:3-17`
  - `/Users/mei/nixos-config/overlays/20-helium.nix:5-14` and `:92-149`
  - `/Users/mei/nixos-config/overlays/30-ai-sidecars.nix:3-49`
- Sidecar versions are duplicated in `/Users/mei/nixos-config/modules/shared/packages.nix:106-113` and docs `/Users/mei/nixos-config/docs/service-notes/ai-sidecars.md:7-31`.

## EXPAND markers verbatim
- none supplied as actionable leads; worker ended with EXPAND tail placeholder only.
