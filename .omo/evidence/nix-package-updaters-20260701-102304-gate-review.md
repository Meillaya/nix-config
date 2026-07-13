# Gate Review: Nix package updaters

recommendation: UNCONDITIONAL APPROVAL

gateReviewerMode: final gate reviewer, read-only product inspection. Report artifact write only.

## originalIntent

The user approved the ULW research recommendation to make Nix-managed package/source pins auto-update through `nix flake update` and the repo update app. The implementation needed to expose repo-local overlay packages as flake packages, preserve `nix run .#update`, add package-local updater hooks for fixed-output packages, centralize sidecar versions, cover non-overlay fixed-output Nix sources, and provide sufficient verification evidence with documented residual risk.

## desiredOutcome

A user can run `nix run .#update` to update flake inputs and repo-local fixed-output pins, can target local package/source updaters by name, can inspect/build local packages through `packages.<system>.<name>`, and can trust updater failures to be explicit rather than silent. Standard Nix flake validation must pass across supported systems.

## userOutcomeReview

The implementation now satisfies the user-visible outcome. Local overlay packages are exposed for all four supported systems. The update app still delegates flake input updates to `nix flake update`, supports help/filtering/local-only/flake-only modes, rejects invalid package selections with clear diagnostics, and includes the Linux Home Manager fixed-output source pins through `linux-home-sources`. Package-local update scripts are present for the fixed-output package overlays, sidecar versions are centralized by deriving `rev = "v${version}"`, and updater mutation scripts now fail loudly on missing substitutions and use atomic replacement.

## checkedArtifactPaths

- `flake.nix`
- `flake.lock`
- `README.md`
- `modules/shared/default.nix`
- `modules/shared/packages.nix`
- `modules/linux/home-manager.nix`
- `modules/nixos/home-manager.nix`
- `hosts/nixos/default.nix`
- `overlays/10-feather-font.nix`
- `overlays/20-helium.nix`
- `overlays/30-ai-sidecars.nix`
- `overlays/40-raycast.nix`
- `.omo/ulw-work/nix-package-updaters-20260701-102304.md`
- `.omo/evidence/nix-package-updaters-20260701-102304-manual-qa.md`
- `.omo/evidence/nix-package-updaters-20260701-102304-code-review.md`

## directVerificationEvidence

Commands run by this gate:

- `nix flake check --no-build` exited 0 with `all checks passed!`.
- `nix flake check --no-build --all-systems` exited 0 with `all checks passed!`.
- `nix eval --json .#packages.aarch64-darwin.feather-font.meta.platforms` exited 0 and returned `["x86_64-linux","x86_64-darwin","aarch64-linux","aarch64-darwin"]`.
- Package metadata/updater eval across `aarch64-darwin`, `x86_64-darwin`, `aarch64-linux`, and `x86_64-linux` exited 0, including updater paths and metadata.
- `nix run .#update -- --help` exited 0 and displayed flake/local update modes.
- `nix run .#update -- --local-only --package does-not-exist` exited 2 with a valid-updater list.
- `nix run .#update -- --local-only --package` exited 2 with usage text.
- Feather updater against a nonmatching temp file exited 1 with `expected exactly one match`.
- `nix eval --raw .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath` exited 0.
- `nix eval --raw .#nixosConfigurations.x86_64-linux.config.system.build.toplevel.drvPath` exited 0.
- `nix build --no-link .#raycast` exited 0.
- `git diff --check` exited 0.
- Generated update/updater scripts inspected with `bash -n` for representative current-system scripts; syntax passed.

## priorBlockerDisposition

1. Feather invalid platforms: RESOLVED. Literal system strings evaluate and all-systems flake check passes.
2. Update app filtering: RESOLVED. Missing and unknown `--package` cases fail non-zero with clear diagnostics.
3. Sidecar rev duplication: RESOLVED. `mkNodeSidecar` derives `src.rev = "v${version}"`; `sync-ai-sidecars` uses package versions.
4. Updater substitution false success: RESOLVED. Feather, Helium group, Raycast, and Linux source updater use checked `re.subn` and `os.replace`; direct nonmatching-file probe fails loudly.
5. Raycast package-local updater robustness: RESOLVED. It includes `git` and resolves repo root before using the default relative overlay path.
6. Non-overlay fixed-output source coverage: RESOLVED. `linux-home-sources` covers Garuda Dr460nized, Beautyline, and Candy Icons pins in `modules/linux/home-manager.nix`.
7. Review artifacts: RESOLVED. Manual QA and code review artifacts exist and are supported by direct gate checks.

## antiSlopAndProgrammingReview

Loaded/consulted:

- `omo:remove-ai-slops`: direct pass checked for false-confidence tests, tautological/deletion-only coverage, brittle updater logic, silent skips, needless abstractions, duplication that creates maintenance burden, and unsupported report claims.
- `omo:programming`: direct pass applied strict failure-at-boundary expectations, no false success, no unnecessary dependency/abstraction, and maintainability review.

Direct pass result:

- No new test files were added, so overfit/deletion-only/implementation-mirroring test concerns are not present.
- The implementation uses real CLI/data-surface evidence rather than tautological unit tests.
- Prior brittle regex mutation risk was resolved with checked substitutions and a negative probe.
- No new external dependency was introduced.
- The code review artifact includes an anti-slop section and its claims are supported by direct command evidence and file inspection.
- Remaining size/complexity risk in `flake.nix` and `overlays/20-helium.nix` is noted as a maintainability risk, but not a blocker for this Nix-focused updater change because the scripts are repo-local, validated through generated shells, and grouped by the package/source pins they mutate.

## blockers

None.

## exactEvidenceGaps

None blocking. Remaining documented risks:

- Stremio/Sublime version discovery depends on upstream HTML shape; scripts are designed to fail rather than silently succeed if parsing breaks.
- `pnpm-10.29.2` remains an exact temporary insecure-package exception and should be removed when nixpkgs no longer requires it.
- Existing deprecation warnings remain during flake checks but do not block validation.

## finalDecision

UNCONDITIONAL APPROVAL
