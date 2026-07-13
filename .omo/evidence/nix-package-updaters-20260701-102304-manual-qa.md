# Manual QA Matrix — Nix package updaters

Surface: CLI/data-shaped Nix flake and update app.

| Criterion | Exact invocation | Expected observable | Result |
| --- | --- | --- | --- |
| RED baseline | `nix eval --json .#packages.aarch64-darwin` before package facade | Missing `packages.aarch64-darwin` output | RED captured in work notepad |
| Local package facade | `nix eval --json .#packages.<system> --apply 'pkgs: builtins.mapAttrs ... pkgs'` for all four systems | Package attrs include versions, metadata, and updater paths | PASS |
| Standard flake validation | `nix flake check --no-build` | Exits 0 with `all checks passed!` | PASS |
| Raycast package build | `nix build --no-link .#raycast` | Exits 0 and builds exposed flake package | PASS |
| Update app help | `nix run .#update -- --help` | Shows flake/local update modes | PASS |
| Targeted Raycast updater | `nix run .#update -- --local-only --package raycast` | Exits 0, prints `Raycast overlay is pinned to 1.104.20` | PASS |
| Targeted Linux source updater | `nix run .#update -- --local-only --package linux-home-sources` | Exits 0, rewrites Linux Home Manager source pins | PASS |
| Unknown updater | `nix run .#update -- --local-only --package does-not-exist` | Exits non-zero with valid updater list | PASS |
| Missing updater arg | `nix run .#update -- --local-only --package` | Exits non-zero with usage text | PASS |
| Checked substitution failure | Run Feather updater with `FEATHER_FONT_OVERLAY_FILE` pointing at a nonmatching temp file | Exits non-zero with `expected exactly one match` | PASS |
| Darwin system eval | `nix eval --raw .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath` | Exits 0 and prints Darwin system drv | PASS |
| NixOS system eval | `nix eval --raw .#nixosConfigurations.x86_64-linux.config.system.build.toplevel.drvPath` | Exits 0 and prints NixOS system drv | PASS |
| Diff hygiene | `git diff --check` | Exits 0 | PASS |

Known warnings:
- `nix flake check --no-build` reports pre-existing deprecation warnings for Home Manager/zsh/ssh, xorg package names, and BEAM package aliases.
- `nix flake check --no-build` warns app outputs lack `meta`; these are warnings, not validation failures.
