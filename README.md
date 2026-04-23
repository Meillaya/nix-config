# nixos-darwin-config

Personal Nix config for:

- macOS via `nix-darwin`
- Linux via `NixOS`
- Existing Linux installs via Determinate Nix + standalone Home Manager

## Recent changes

- `omx` is now launched through a Nix-managed wrapper, with tmux/non-interactive shell fixes.
- Shell UX is aligned across `zsh`, `bash`, `fish`, and Readline-backed shells.
- Package lookup now works through `nix run .#search-pkgs -- <query>` and installed `nixpkgs-search`.
- Non-NixOS Linux now has a standalone Home Manager path for existing machines like Arch Linux with Niri.

## Search and add packages

Search before installing:

```bash
nix run .#search-pkgs -- ghostty
```

Or, after your config is already applied:

```bash
nixpkgs-search ghostty
```

Then add the chosen attribute to:

- `modules/shared/packages.nix` for all machines
- `modules/darwin/packages.nix` for macOS only
- `modules/nixos/packages.nix` for NixOS only
- `modules/standalone-linux/packages.nix` for existing non-NixOS Linux machines

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

## Existing Linux installs

For an existing Linux machine such as Arch Linux with Niri, this repo now exposes a standalone Home Manager config built for Determinate Nix.

Install Determinate Nix first using the official installer:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Then switch the standalone home config:

```bash
nix run .#home-switch
```

That defaults to the generic `standalone-linux` Home Manager configuration on `x86_64-linux`, using your current `USER` and `HOME`.

After the first switch, normal updates are:

```bash
home-manager switch --flake .#standalone-linux --impure
```

If you need to override the detected user or home directory on a machine:

```bash
NIXOS_CONFIG_USER=mei NIXOS_CONFIG_HOME=/home/mei nix run .#home-switch
```

## Secrets

Private values live in the separate `nix-secrets` repo and are pulled in as a flake input.
