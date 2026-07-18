# nixos-darwin-config

Personal Nix config for:

- macOS via `nix-darwin`
- Linux via `NixOS`
- Existing Linux installs, including WSL, via Determinate Nix + standalone Home Manager

## Recent changes

- The flake now follows Den's dendritic model: flake-parts owns output
  composition, Den owns machine/home entities, and capability aspects own
  configuration. See `docs/architecture/dendritic.md`.
- Nushell is the primary login and Ghostty shell. Bash, Zsh, and Fish remain
  installed, configured, and available as secondary shells.
- Shell UX is aligned across `zsh`, `bash`, `fish`, and Readline-backed shells.
- Package lookup works through `nix run .#search-pkgs -- <query>`.
- Non-NixOS Linux now has a standalone Home Manager path for existing machines like Arch Linux with Niri.
- Niri config is shared between NixOS and standalone Linux Home Manager.
- Noctalia external monitor brightness is documented in
  `docs/service-notes/noctalia-ddc-brightness.md`; root-level DDC/CI setup on
  non-NixOS systems remains an explicit manual OS task.

## Search and add packages

Search before installing:

```bash
nix run .#search-pkgs -- ghostty
```

Then add the chosen attribute to:

- `modules/shared/packages.nix` for all machines
- `modules/darwin/packages.nix` for macOS only
- `modules/nixos/packages.nix` for NixOS only
- `modules/standalone-linux/packages.nix` for existing non-NixOS Linux machines


## Update packages

Use the repo update app instead of plain `nix flake update` when you want
flake inputs and the shared Linux Home Manager source pins to move together:

```bash
nix run .#update
```

This runs `nix flake update` for flake inputs and then runs the repo-local
source updater for the shared Linux Home Manager assets.

You can pass normal flake-update input names after `--`:

```bash
nix run .#update -- nixpkgs home-manager
```

Useful update modes:

```bash
nix run .#update -- --flake-only
nix run .#update -- --local-only --package linux-home-sources
```

## macOS

The declared Apple Silicon machine is evaluation-only and operationally
disabled, so the flake exposes a build-only Darwin app:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#build
```

Live `build-switch`, generation cleanup, update, and credential apps are not
exposed until validated machine authority is enrolled. Native Darwin build,
activation, relogin, rollback, TCC, and runtime checks remain **NOT VERIFIED**.

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

The current NixOS declarations are evaluation-only or pending machine
enrollment. Build a selected toplevel without activating it:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#build
```

Accordingly, Linux does not expose `build-switch` or `clean` apps. Those names
remain reserved until machine boot and storage authority is enrolled; there is
currently no repo-app path to switch/boot NixOS or delete system generations.
Disabled device/capability enrollment only suppresses enrollment-specific
projection and does not force baseline upstream services off.

## Existing Linux installs

For an existing Linux machine such as Arch Linux with Niri, or for a WSL distro on Windows, this repo exposes the existing standalone Home Manager surface built for Determinate Nix. WSL does **not** get a separate flake output here; use the same `standalone-linux` / `standalone-linux-aarch64` targets that other non-NixOS Linux machines use.

Install Determinate Nix first using the official installer:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

If the WSL distro already has upstream Nix, follow Determinate's migration guide first before switching this repo's Home Manager config.

Then switch the standalone home config:

```bash
nix run .#home-switch
```

That defaults to the generic `standalone-linux` Home Manager configuration on `x86_64-linux`. Both standalone targets have the explicit identity `mei` at `/home/mei`; they do not derive identity from the invoking shell. On Windows on ARM, use `nix run .#home-switch -- --target standalone-linux-aarch64` instead.
The wrapper uses a timestamped `hm-backup-<timestamp>` extension by default, so
any pre-existing dotfiles that Home Manager needs to take over are backed up on first switch.

After the first switch, normal updates are:

```bash
home-manager switch --flake .#standalone-linux
# or on Windows on ARM / aarch64-linux:
home-manager switch --flake .#standalone-linux-aarch64
```

To read Home Manager news with this flake-based setup, use:

```bash
nix run .#home-news
```

To sync ignored local secrets from a private repo into a writable checkout,
identify that checkout explicitly with `--repo-root` or
`NIX_CONFIG_REPO_ROOT`:

```bash
NIX_SECRETS_REPO=git@github.com:Meillaya/nix-screts.git \
  nix run .#sync-secrets -- --repo-root "$PWD"
```

`--repo-root` takes precedence over `NIX_CONFIG_REPO_ROOT`. If neither is
supplied, `sync-secrets` fails closed, even when invoked from inside a Git
checkout; there is no detected-checkout fallback. The cloned secrets-repository
URL is never logged. The sync recursively rejects symlinks in both its source
and destination paths, and replaces live files with an atomic same-filesystem
exchange rather than an in-place write.

Standalone identity is part of the Den home entity declaration. To support a different user or home directory, add a distinct typed home entity and output instead of relying on ambient environment overrides.

For the repo-specific WSL notes, including the Determinate-only requirement verified against official docs on Friday, July 17, 2026, see `docs/service-notes/wsl-standalone-home-manager.md`.

## Secrets

The ignored local `secrets/` directory is an out-of-store staging boundary.
Home Manager does not ingest or manage the synced plaintext Kavita or Calibre
files and does not create `home.file.source` links for them. After syncing,
install only the files an application needs as a manual runtime workflow
outside Nix evaluation, for example:

```bash
install -d -m 0700 "$HOME/Documents/Kavita/config" "$HOME/.config/calibre"
install -m 0600 secrets/kavita/appsettings.json \
  "$HOME/Documents/Kavita/config/appsettings.json"
install -m 0600 secrets/calibre/{global.py.json,gui.py.json,customize.py.json} \
  "$HOME/.config/calibre/"
```

These commands are a manual runtime workflow, not a Home Manager activation or
proof that provider credentials were rotated.

Only encrypted material intended for `agenix` may be referenced by
`modules/*/secrets.nix`; do not add ignored plaintext application state to a
flake source or Nix path.
