# ULW Research Synthesis — Nix-managed package updates in this flake

## Best-practice architecture

Use a layered update model:

1. Keep `nix flake update` responsible for flake inputs only.
   - It updates `flake.lock`; it does not rewrite inline fixed-output hashes in `.nix` files.

2. Expose repo-local overlay packages under `packages.<system>.<name>`.
   - Keep overlays for consuming them in NixOS/nix-darwin systems.
   - Add a flake package facade so tools can target them with `nix build .#name`, `nix flake check`, and `nix-update --flake`.

3. Put update behavior on packages, not only in a global script.
   - Use `passthru.updateScript` per local derivation.
   - Use `nix-update-script { }` when package metadata is conventional.
   - Use custom scripts for vendor endpoints, multi-architecture binaries, multiple hashes, or generated dependency hashes.

4. Keep `nix run .#update` as the single user-facing wrapper.
   - Run `nix flake update` for inputs.
   - Then run package-local update scripts or `nix-update --flake --use-update-script --build` for repo-local packages.
   - Finish with eval/build verification for the affected systems.

5. Use low-level helpers (`nix store prefetch-file`, `nurl`, `update-source-version`) inside scripts.
   - Do not adopt a heavy source generator unless the local package inventory grows enough to justify it.

## Tool choices

- Primary: flake lock updates for flake inputs.
- Primary for local package updates: `passthru.updateScript` plus `nix-update --flake`.
- Helper: `nurl` / `nix store prefetch-file` for URLs and hashes.
- Maybe later: `nvfetcher` if the repo gains many simple upstream source pins and wants generated `_sources` files.
- Maybe for non-package source pins: `npins`.
- Avoid: `niv` for new work.

## Repo-specific package classification

### Already good pattern
- `overlays/40-raycast.nix`: custom update script is appropriate because Raycast uses vendor release endpoints and multiple Darwin architecture hashes.

### Add package-local updater scripts
- `overlays/20-helium.nix`
  - `helium` Linux AppImages and macOS DMGs: likely custom or semi-custom GitHub-release updater due multi-arch assets.
  - `omniwm`: likely GitHub-release/package updater.
  - `stremio`: likely custom endpoint updater.
  - `sublimeText`: likely custom vendor endpoint updater.
- `overlays/30-ai-sidecars.nix`
  - `oh-my-codex-sidecar` and `oh-my-claude-sisyphus-sidecar`: expose as flake packages and use `nix-update --flake` where possible; handle `npmDepsHash`/generated dependency hashes in the package update path.
  - Remove or centralize duplicated versions in `modules/shared/packages.nix` so update state has one source of truth.
- `overlays/10-feather-font.nix`
  - Add a minimal updater if this is an intentionally moving upstream; otherwise treat as a deliberate fixed asset pin.
- `modules/linux/home-manager.nix`
  - `garudaDr460nized`, `beautylineSrc`, `candyIconsSrc`: either move these source pins into local package attrs with `passthru.updateScript`, or use `npins` if they are non-package source assets.

## Immediate implementation sequence

1. Add `packages = forAllSystems (...)` in `flake.nix`, re-exporting the local overlay derivations.
2. Move duplicated package version constants into package attrs/shared attrsets.
3. Add `passthru.updateScript` to each local fixed-output package.
4. Extend `nix run .#update` to run local updaters after `nix flake update`.
5. Add verification targets: evaluate all systems and build a representative subset of packages.

## Important caveat

Flake evaluation can ignore newly-created untracked files in a Git worktree. Any new overlay or updater files should be at least intent-to-add staged before relying on flake evaluation.

## Sources

- Nix flake update manual: https://nix.dev/manual/nix/2.25/command-ref/new-cli/nix3-flake-update
- nixpkgs manual, `passthru.updateScript`: https://nixos.org/manual/nixpkgs/unstable/
- NixOS Wiki automatic updates: https://wiki.nixos.org/wiki/Nixpkgs/Automatic_Updates
- nix-update README: https://github.com/Mic92/nix-update
- nixpkgs `update-source-version`: https://github.com/NixOS/nixpkgs/blob/master/pkgs/common-updater/scripts/update-source-version
- npins dependency management guide: https://nix.dev/guides/recipes/dependency-management.html
- nvfetcher README: https://github.com/berberman/nvfetcher
