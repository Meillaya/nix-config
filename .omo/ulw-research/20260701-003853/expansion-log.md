# Expansion Log

Core question: Find the best way to make repo-managed Nix packages update using Nix flakes/packages best practices.

## Phase 0 axes
- Official Nix flakes/update semantics.
- nixpkgs package updater conventions and passthru.updateScript.
- Pin-management/update-tool ecosystem: nvfetcher, npins, nix-update, update-source-version.
- Repo-local fixed-output sources and constraints.
- Practical verification of commands/tool behavior.

## Wave 1 return: repo fixed pins
- Captured inventory in `wave-1-codebase-repo-fixed-pins.md`.
- Open leads for synthesis: decide whether each manual pin should be flake input, nvfetcher/npins managed source, nix-update-compatible package, or custom passthru.updateScript.

## Wave 1 return: tooling evaluation
- Captured in `wave-1-tooling-evaluation.md`.
- Leads to expand locally: verify nix-update flake mode/help and investigate whether repo packages can be exposed as `packages` outputs to enable `nix-update --flake`.

## Wave 1 return: nixpkgs conventions
- Captured in `wave-1-nixpkgs-update-conventions.md`.
- Leads to expand locally: inspect nixpkgs `nix-update-script` availability in this repo's package set; test `nix-update --flake` behavior against current outputs.

## Wave 1 return: OSS patterns
- Captured in `wave-1-oss-patterns.md`.
- Leads to expand locally: inspect AppImage/DMG package-local update style against this repo's `mkDarwinApp` multi-package overlay shape.

## Wave 1 return: official flake semantics
- Captured in `wave-1-official-flake-semantics.md`.
- Expansion wave 2 opened for repo-output shape and `nix-update --flake` compatibility.

## Wave 2 local expansion opened
- Runtime thread limit allowed one worker only.
- Orchestrator locally verified flake output shape, nix-update help, and package exposure.
