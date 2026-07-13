# Wave 1: tooling evaluation

Worker: Hubble (`019f1bf9-7381-7ad2-918f-438113d492fd`)

## Key findings
- Recommended layered workflow:
  1. Flake inputs + `nix flake update` for repo-level dependencies.
  2. `nix-update` as default package updater for local overlay packages.
  3. `nurl`/`nix-prefetch-url` for adding or rescuing binary pins.
  4. `nvfetcher` only when many binary apps need a generated source registry.
  5. `npins` for non-flake pins, not package derivation rewrites.
- `nix-update` supports flake outputs, build/test/run/review flags, dependency hashes including npmDepsHash, and `passthru.updateScript` execution.
- For weird vendor binary URLs, use custom `passthru.updateScript` with `curl` + prefetch/update-source-version style logic.
- For this repo, a personal flake with a modest number of overlays should avoid adding `nvfetcher` unless local package count/complexity grows.

## EXPAND markers verbatim
- none supplied as actionable leads; worker ended with EXPAND tail heading only.
