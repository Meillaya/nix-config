# Verification — current flake/tooling behavior

## Local command evidence

### Current flake package outputs
Command attempted:

```sh
nix eval --json .#packages.aarch64-darwin
```

Result: failed because the flake does not currently provide `packages.aarch64-darwin`.

Implication: local overlay packages cannot yet be targeted as first-class flake packages by tools like `nix-update --flake`; they are only visible through system configurations/overlays.

### Local packages currently visible in Darwin systemPackages
Command evaluated `darwinConfigurations.aarch64-darwin.config.environment.systemPackages` and filtered local package names.

Observed versions:

- `helium-0.11.5.1`
- `omniwm-0.5.2.1`
- `raycast-1.104.20`
- `stremio-5.1.21`
- `sublime-text-4200`

### nix-update feature availability
Command:

```sh
nix run nixpkgs#nix-update -- --help | rg -n -e "--flake|override-filename|build|test|use-update-script|subpackage|attribute" -C 2
```

Observed options include:

- `-F, --flake`
- `--build`
- `--test`
- `-u, --use-update-script`
- `--override-filename`
- `--system`
- `-s, --subpackage`

Implication: the current nixpkgs-provided `nix-update` has the features needed for the recommended wrapper: target flake outputs, build/test updated packages, delegate to `passthru.updateScript`, and patch overlay files explicitly.
