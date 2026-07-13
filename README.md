# nixos-darwin-config

Personal Nix config for:

- macOS via `nix-darwin`
- Linux via `NixOS`
- Existing Linux installs via Determinate Nix + standalone Home Manager

## Recent changes

- The flake now follows Den's dendritic model: flake-parts owns output
  composition, Den owns machine/home entities, and capability aspects own
  configuration. See `docs/architecture/dendritic.md`.
- Nushell is the primary login and Ghostty shell. Bash, Zsh, and Fish remain
  installed, configured, and available as secondary shells.
- `omx` is now launched through a Nix-managed wrapper, with tmux/non-interactive shell fixes.
- Shell UX is aligned across `zsh`, `bash`, `fish`, and Readline-backed shells.
- Package lookup now works through `nix run .#search-pkgs -- <query>` and installed `nixpkgs-search`.
- Non-NixOS Linux now has a standalone Home Manager path for existing machines like Arch Linux with Niri.
- Niri config is shared between NixOS and standalone Linux Home Manager.
- Noctalia external monitor brightness is documented in
  `docs/service-notes/noctalia-ddc-brightness.md`; standalone Linux installs
  include the `setup-ddc-brightness` helper for DDC/CI I2C access.

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


## Update packages

Use the repo update app instead of plain `nix flake update` when you want
flake inputs and supported repo-local fixed-output package pins to move together:

```bash
nix run .#update
```

This runs `nix flake update` for flake inputs and then runs explicit updaters
for package overlays that cannot be represented as flake inputs. Package
overlays are also exposed under `packages.<system>.<name>` so update tools can
target them directly:

```bash
nix build .#raycast
nix build .#helium
```

You can pass normal flake-update input names after `--`:

```bash
nix run .#update -- nixpkgs home-manager
```

Useful update modes:

```bash
nix run .#update -- --flake-only
nix run .#update -- --local-only --package raycast
nix run .#update -- --local-only --package linux-home-sources
```

Current repo-local updater coverage includes Raycast, Helium, OmniWM, Stremio,
Sublime Text, Feather Font, the AI sidecar packages, and the Linux Home Manager
theme/icon source pins.

## macOS

Apply the active Darwin config:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#build-switch
```

## NixOS

This repo still includes bootstrap placeholders for Linux host values.
The NixOS host enables Niri and links the shared `~/.config/niri/config.kdl`
through Home Manager. Niri is the only graphical login session.

The managed user is declared by the `mei` aspect. Both Linux and macOS accounts
use Nushell by default, while the other managed shells can be launched directly:

```nu
bash
zsh
fish
```

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
The wrapper also passes `-b hm-backup` by default so any pre-existing dotfiles
that Home Manager needs to take over are backed up on first switch.

After the first switch, normal updates are:

```bash
home-manager switch --flake .#standalone-linux --impure
```

To read Home Manager news with this flake-based setup, use:

```bash
nix run .#home-news
```

To sync ignored local secrets from a private repo into `./secrets`, use:

```bash
NIX_SECRETS_REPO=git@github.com:Meillaya/nix-screts.git nix run .#sync-secrets
```

If you need to override the detected user or home directory on a machine:

```bash
NIXOS_CONFIG_USER=mei NIXOS_CONFIG_HOME=/home/mei nix run .#home-switch
```

## Secrets

The repo ships with an ignored local `secrets/` directory so standalone Linux
machines can bootstrap without GitHub SSH access on first switch.

If you want to use `agenix`-managed private files, place them under `secrets/`
locally (or sync your private secrets repo into that directory) before
referencing them from the `modules/*/secrets.nix` files.
