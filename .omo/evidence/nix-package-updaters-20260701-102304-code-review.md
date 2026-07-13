# Code Review — Nix package updater architecture

## Scope
Reviewed changed Nix/update paths for updater recursion, shell quoting, Nix string interpolation, platform leaks, fixed-output hash semantics, and false-success updater behavior.

## Findings addressed

1. Invalid Feather `meta.platforms`
   - Fixed by using literal system strings: `x86_64-linux`, `x86_64-darwin`, `aarch64-linux`, `aarch64-darwin`.
   - Evidence: `nix eval --json .#packages.aarch64-darwin.feather-font.meta.platforms` exits 0.

2. Update app false-success filtering
   - Fixed `--package` missing-arg handling with usage text.
   - Fixed unknown package handling with non-zero exit and a valid updater list.
   - Evidence: adversarial commands for missing and unknown package names both fail intentionally with diagnostics.

3. Sidecar version duplication
   - Fixed by deriving `src.rev = "v${version}"` inside `mkNodeSidecar`.
   - `sync-ai-sidecars` derives npm versions from package attrs.

4. Updater regex false success
   - Replaced raw `re.sub(..., count=1)` with checked `re.subn` helpers that require exactly one replacement.
   - Wrote replacements atomically with `os.replace`.
   - Evidence: Feather updater against a nonmatching temp file fails with `expected exactly one match`.

5. Raycast package-local robustness
   - Added `git` runtime input and repo-root resolution before using default relative overlay path.

6. Fixed-output Home Manager source pins
   - Added `linux-home-sources` updater to the repo update app.
   - It updates Garuda Dr460nized, Beautyline, and Candy Icons source URLs/hashes with unpacked `fetchzip` hashes.
   - Evidence: real `nix run .#update -- --local-only --package linux-home-sources` completed and rewrote source pins.

7. Standard flake validation surfaced stale template issues
   - Replaced `builtins.readFile (pkgs.replaceVars ...)` with pure template substitution for Polybar user modules.
   - Replaced NixOS `%HOST%`/`%INTERFACE%` placeholders with concrete generated config defaults.
   - Evidence: `nix flake check --no-build` exits 0.

## Anti-slop review

- No new dependencies were added.
- The repo update app remains the single user-facing entry point.
- Package-local updater scripts live with the package definitions they mutate.
- Scripts fail loudly on missing upstream versions, unknown updater names, and failed regex matches.
- Large binary updater scripts were not executed for every package to avoid unnecessary DMG/AppImage downloads; their discovery logic and generated scripts were evaluated, and Raycast plus Linux source updaters were exercised through the real update app.

## Remaining risks

- Vendor pages for Stremio and Sublime Text are parsed from HTML; if upstream changes markup, checked substitutions and missing-version checks should fail rather than silently succeeding.
- `pnpm-10.29.2` is temporarily permitted as an exact insecure package because the updated nixpkgs lock marks it insecure; remove the exception once nixpkgs moves past that CVE window.
