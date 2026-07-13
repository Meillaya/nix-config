# ULW Work Notepad — Nix package updater architecture

Tier: HEAVY — touches flake outputs, package overlay update architecture, and repo-wide update command behavior.
Skills used:
- omo:ulw-research — user explicitly invoked it; prior synthesis is the approved research basis.
- ultrawork mode — hook activated; use evidence-first implementation and verification.

Success criteria:
1. Local overlay packages are exposed as `packages.<system>.<name>` for supported systems.
2. Repo-level `nix run .#update` still updates flake inputs and can run local package updaters.
3. Package-local updater convention is present for fixed-output packages, with custom scripts where needed and safe stubs/skip logic where automation is not yet trustworthy.
4. Nix evaluation/build/update surfaces verify the changed behavior.

Manual QA channel:
- CLI/data-shaped surface. Exact invocations: `nix eval .#packages.<system>.<name>.version`, `nix build --no-link .#<package>`, and `nix run .#update -- --help`/targeted safe runs. PASS = commands exit 0 and output expected package/update data.

RED evidence:
- Current flake package output missing: `nix eval --json .#packages.aarch64-darwin` fails because no packages output exists.

## Verification evidence

- RED: before implementation, `nix eval --json .#packages.aarch64-darwin` failed because the flake had no packages output.
- GREEN: `nix eval --json .#packages.aarch64-darwin --apply ...` returned local packages with `hasUpdateScript = true` for Raycast, Helium, OmniWM, Stremio, Sublime Text, Feather Font, and AI sidecars.
- GREEN: `nix eval --json .#packages.x86_64-linux --apply ...` returned Linux local packages with updater scripts.
- GREEN: `nix run .#update -- --help` built the update app and all package updater script derivations, showing the new update modes.
- GREEN: `nix build --no-link .#raycast` built the exposed Raycast flake package.
- GREEN: `nix run .#update -- --local-only --package raycast` ran the real update command and reported `Raycast overlay is pinned to 1.104.20`.
- GREEN: `nix eval --raw .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath` returned `/nix/store/5hvwp1awn9s127lf1bqavrs7m95n3q5g-darwin-system-26.11.a1fa429.drv`.

## Findings

- Updated nixpkgs currently marks `pnpm-10.29.2` insecure. Added an exact `permittedInsecurePackages = [ "pnpm-10.29.2" ];` exception so flake input updates do not break Darwin evaluation. This is intentionally narrow and should be revisited when nixpkgs moves pnpm past the CVE window.
- Embedded Home Manager theme/icon source pins remain intentionally out of package-local updater coverage until they are moved into package attrs or npins-managed sources.

## Self-review

- Re-read diff for shell quoting, Nix string interpolation, update-script recursion, and platform filtering.
- The sidecar scripts call `nix-update --flake` directly and the repo update app calls package `passthru.updateScript` directly, avoiding `--use-update-script` recursion.
- GREEN: version-discovery probes for Helium Linux/macOS, OmniWM, Feather Font, Stremio macOS, and Sublime Text all returned current upstream versions/builds without downloading the large payloads.
- GREEN: `git diff --check` reported no whitespace errors.
- GREEN: `nix eval --json .#packages.x86_64-darwin --apply 'pkgs: builtins.attrNames pkgs'` and `nix eval --json .#packages.aarch64-linux --apply 'pkgs: builtins.attrNames pkgs'` returned the expected platform-filtered local package names.

## Gate rejection fixes

- Fixed Feather metadata platforms and verified metadata eval.
- Added update-app validation for missing/unknown `--package` values.
- Derived sidecar `rev` from `version` in `mkNodeSidecar`.
- Replaced updater `re.sub` calls with checked `re.subn` plus atomic writes.
- Made Raycast updater resolve repo root and include `git`.
- Added `linux-home-sources` updater for Garuda/Beautyline/Candy fixed-output source pins in `modules/linux/home-manager.nix`.
- Fixed NixOS flake-check blockers: pure Polybar template replacement and concrete generated hostnames.
- Added `.omo/evidence/nix-package-updaters-20260701-102304-manual-qa.md` and `.omo/evidence/nix-package-updaters-20260701-102304-code-review.md`.

## Fresh verification after rejection

- GREEN: `nix flake check --no-build` exits 0 with `all checks passed!`.
- GREEN: `nix eval --json .#packages.aarch64-darwin.feather-font.meta.platforms` exits 0.
- GREEN: package metadata/updater eval across `aarch64-darwin`, `x86_64-darwin`, `aarch64-linux`, and `x86_64-linux` exits 0.
- GREEN: `nix run .#update -- --local-only --package does-not-exist` exits non-zero with valid updater list.
- GREEN: `nix run .#update -- --local-only --package` exits non-zero with usage text.
- GREEN: Feather updater against a nonmatching temp file exits non-zero with checked-substitution error.
- GREEN: `nix run .#update -- --local-only --package linux-home-sources` exits 0 and updates Linux Home Manager source pins.
- GREEN: `nix run .#update -- --local-only --package raycast` exits 0 and reports Raycast pinned to 1.104.20.
- GREEN: Darwin and NixOS toplevel drv path evals exit 0.
- GREEN: `git diff --check` exits 0.

## Gate approval

- UNCONDITIONAL APPROVAL received from gate reviewer.
- Gate artifact: `.omo/evidence/nix-package-updaters-20260701-102304-gate-review.md`.
- Reviewer directly verified `nix flake check --no-build --all-systems`, package metadata/updater evals, update help, invalid `--package` cases, Feather negative substitution probe, Darwin/NixOS drv evals, `nix build --no-link .#raycast`, and `git diff --check`.

## 2026-07-01T10:56:04-04:00 fresh post-hook verification

Recorded fresh evidence at `.omo/evidence/nix-package-updaters-20260701-105604-fresh-post-hook.md`. Passed: git diff check, update CLI help/error handling, all package facade evals, nix flake check --no-build --all-systems, raycast build smoke, NixOS drv eval, Darwin smoke/package evals, raycast updater smoke. Noted external disk exhaustion for full Darwin toplevel drv eval.
