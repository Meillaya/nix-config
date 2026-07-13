# Wave 2 — nix-update --flake compatibility and flake output shape

## Question
Can repo-local packages that are currently provided only through overlays be updated idiomatically with `nix-update --flake`, and what flake output shape should this repository expose?

## Findings
- `nix-update --flake` can target flake packages and also supports legacy package-set paths, but `packages.<system>.<name>` is the best public shape for local derivations.
- Overlay-backed packages should still be exported through a thin `packages` facade. Keep overlays for system consumption and custom nixpkgs imports, but publish the resulting derivations for tooling.
- For overlay-defined packages, use `--override-filename <overlay-file>` when invoking `nix-update`, because automatic filename discovery can resolve to the original nixpkgs source rather than the local overlay.

## Recommendation carried into synthesis
Add `packages = forAllSystems (...)` to `flake.nix`, re-exporting local overlay derivations like `raycast`, `helium`, `omniwm`, `stremio`, `sublimeText`, AI sidecars, and source packages that are worth building independently. Use `nix-update --flake --override-filename <file>` for packages that can be mechanically updated; keep custom `passthru.updateScript` for nonstandard/multi-asset binaries.

## Sources noted by expansion worker
- https://github.com/Mic92/nix-update#flakes
- https://github.com/Mic92/nix-update#updating-a-package-defined-in-a-different-file
- https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix#installables
- https://nix.dev/manual/nix/2.22/command-ref/new-cli/nix3-flake-check
- https://nix.dev/manual/nix/2.23/command-ref/new-cli/nix3-search
- https://github.com/Mic92/nix-update/issues/632
