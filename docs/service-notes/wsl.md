# WSL with Determinate Nix

The WSL path uses the same `standalone-linux` Home Manager release output as
other non-NixOS Linux systems, but selects a CLI/virtualization package profile
and disables Niri and Noctalia. It does not create a second mutable package
owner.

From an Ubuntu, Debian, or other systemd-enabled WSL distribution:

```bash
./bin/install-determinate-nix
```

The bootstrap script downloads the pinned Determinate installer 3.21.0 for the
current architecture and authenticates both its exact byte size and SHA-256
before execution. Restart the WSL instance when the installer requests it.

Then clone this repository and activate the WSL profile:

```bash
nix run .#wsl-switch
```

The wrapper refuses to run outside WSL, sets the explicit `wsl` profile for the
impure standalone identity arguments, and preserves colliding files using a
timestamped Home Manager backup extension. Docker, Podman, Incus, and Vagrant
are installed as clients; their daemons remain owned by WSL, Docker Desktop, or
the surrounding Windows host.
