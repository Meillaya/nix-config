# nixos-darwin-config

Personal Nix config for:

- macOS via `nix-darwin`
- Linux via `NixOS`

## macOS

Apply the active Darwin config:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#build-switch
```

## NixOS

This repo still includes bootstrap placeholders for Linux host values.

To materialize them on a Linux machine:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#apply
```

## Secrets

Private values live in the separate `nix-secrets` repo and are pulled in as a flake input.
