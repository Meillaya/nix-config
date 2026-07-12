# Dendritic configuration architecture

This repository uses [Den](https://github.com/denful/den) as its entity and
aspect layer and flake-parts as its only outer output composer. Den is pinned to
an audited revision in `flake.nix`; review Den's migration notes and rerun all
cross-platform evaluations before changing that pin.

## Composition boundaries

`flake.nix` intentionally contains only inputs and one `mkFlake` call.
`import-tree` loads the flake modules under `modules/flake/`:

- `dendritic.nix` loads Den plus the entity/aspect trees.
- `systems.nix` declares the four supported evaluation systems.
- `packages.nix`, `apps.nix`, and `dev-shells.nix` own normal flake-parts
  `perSystem` outputs.
- `outputs.nix` exposes the composed overlay without mixing package output
  construction into machine configuration.

Den exclusively creates `nixosConfigurations`, `darwinConfigurations`, and
`homeConfigurations`. Do not reintroduce `nixosSystem`, `darwinSystem`, or
`homeManagerConfiguration` calls in `flake.nix`.

## Entities

`modules/entities/hosts.nix` is the inventory. It declares:

- `x86_64-linux` and `aarch64-linux` NixOS machines;
- `x86_64-darwin` and `aarch64-darwin` macOS machines;
- `standalone-linux` and `standalone-linux-aarch64` Home Manager outputs; and
- the `mei` user on each managed host.

Entity declarations stay thin: identity, architecture, attached aggregate
aspect, and user/home membership. Put behavior in an aspect, never in the
registry.

## Aspects and ownership

The host aggregates under `modules/aspects/hosts/` compose capabilities:

- `nixos-workstation` includes Nix policy, the NixOS baseline, disk layout,
  secure bootstrap-password lifecycle, secrets, Niri, and Linux desktop home
  configuration.
- `darwin-workstation` includes Nix policy, macOS defaults/packages, Dock,
  secrets, and Darwin Home Manager configuration.
- `standalone-linux` combines the shared `mei` home with standalone-only Niri,
  package, secret, and writable Codex behavior.

Leaf aspects under `modules/aspects/features/` own one coherent capability.
The `mei` aspect under `modules/aspects/users/` owns cross-platform user and
Home Manager behavior. Home Manager content must remain on a user aspect or be
delivered explicitly with `provides.to-users` for a genuinely host-selected
payload. A host-class module must not request Den's `user` argument; current Den
silently suppresses that route.

## Shell policy

Nushell is configured explicitly rather than through
`den.batteries.user-shell`, because NixOS and nix-darwin do not expose a matching
OS-level `programs.nushell` option.

- NixOS and Darwin register Nushell, Bash, Zsh, and Fish as valid shells.
- `users.users.mei.shell` points to the pinned Nushell package.
- Home Manager enables all four shells.
- Ghostty, Konsole, and standalone Kitty profiles use the absolute Nix-store Nu path with
  `--login`.
- tmux inherits the account shell.
- OMX's internal wrapper deliberately keeps its Zsh/Bash compatibility path;
  interpreter-specific scripts and `/bin/sh` shebangs are not rewritten.

## Linux desktop policy

Niri is the default display-manager session on NixOS. Noctalia is enabled through
its upstream NixOS module on NixOS hosts and its upstream Home Manager module on
standalone Linux hosts. Both modules start Noctalia as a systemd user service
wanted by `graphical-session.target`; do not add a second
`spawn-at-startup "noctalia"` entry to the shared Niri configuration.

The cross-host evaluation test keeps the primary graphical application set in
sync between NixOS and standalone Linux. Add generally useful Linux desktop apps
to both package surfaces, or intentionally document why a package is host-only.

After pulling this configuration on an existing NixOS machine, apply it with:

```bash
cd ~/nix-config
git pull --ff-only
sudo nixos-rebuild switch --flake .#x86_64-linux
```

Log out and back in after changing the default graphical session. In the login
manager, choose Niri once if an older saved BSPWM session overrides the new
default. Verify Noctalia with:

```bash
systemctl --user status noctalia.service --no-pager
journalctl --user -u noctalia.service -b --no-pager
```

## Adding configuration

1. Add a leaf aspect when the behavior is a reusable capability.
2. Include it from the appropriate host aggregate.
3. Put cross-platform personal programs/files on `den.aspects.mei.homeManager`.
4. Keep packages/apps/dev shells in flake-parts, not Den entities.
5. Avoid recursive legacy imports, string-based profile selectors, lateral
   reads of unrelated configuration, and hidden `specialArgs` plumbing.

Before applying a change, run:

```bash
bash tests/dendritic-architecture.sh
bash tests/dendritic-boundaries.sh
bash tests/dendritic-apps.sh
nix-instantiate --eval --strict tests/dendritic-config-eval.nix
bash tests/dendritic-shells.sh
nix flake check --all-systems
```

Disk and first-install password behavior has separate destructive-risk tests;
run every `tests/bootstrap-password-*` script after changing NixOS aspects or
installation documentation.
