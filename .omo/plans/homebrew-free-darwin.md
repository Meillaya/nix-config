# homebrew-free-darwin - Work Plan

## TL;DR (For humans)

**What you'll get:** Your Mac config stops depending on Homebrew. Nix will own the tools and apps it can already provide, while the few apps that do not have safe Nix packages yet are explicitly documented instead of being kept through casks.

**Why this approach:** The lowest-risk path is to remove Homebrew wiring first and use verified Nix packages already available in your pinned Darwin package set. Packaging Helium, OmniWM, Stremio, and Sublime now would add new trust/license/hash decisions, so the default plan defers those instead of sneaking Homebrew back in.

**What it will NOT do:** It will not uninstall `/opt/homebrew` automatically. It will not add third-party flakes or local binary app packages in the first pass. It will not reconfigure your window manager or update unrelated flake inputs.

**Effort:** Medium
**Risk:** Medium - broad but mechanical config deletion plus macOS GUI app behavior that must be checked after switch.
**Decisions to sanity-check:** Default gap policy: Helium, OmniWM, Stremio, and Sublime are removed from declarative Homebrew management now and documented as manual/vendor/future-packaging follow-up.

Your next move: approve this plan, or override the gap policy before implementation. Full execution detail follows below.

---

> TL;DR (machine): Medium-risk mechanical migration: remove nix-homebrew/Homebrew config, add verified Nix replacements, prune lockfile, verify eval/build/grep, leave system Homebrew uninstall as explicit post-switch action.

## Scope
### Must have
- Remove Homebrew flake inputs and nix-homebrew Darwin module wiring from `flake.nix`.
- Remove nix-darwin `homebrew = { ... };` configuration and delete/retire `modules/darwin/casks.nix`.
- Remove `brewPinUpdate`, active Homebrew update docs, and `/opt/homebrew` shell PATH injection.
- Remove `/opt/homebrew` fallback/message from `omxLauncher` unless the implementation discovers it is still required by a non-Homebrew compatibility contract; if retained, document the exception and keep it out of PATH.
- Add direct Nix replacements that are verified in the current `aarch64-darwin` package set, especially `ast-grep`, `mcp-nixos`, and Nix-packaged GUI replacements for the removed casks where appropriate.
- Keep or confirm already-present Nix replacements: `claude-code`, `codex`, `zed-editor`, `gh`, `go`, `python3`, `zig`, `uv`, `helix`, `micro`, `neovim`, `cocoapods`, `omniorb`, fonts already present.
- Prune `flake.lock` so removed Homebrew/nix-homebrew inputs no longer appear.
- Replace the Homebrew update workflow doc with a no-Homebrew migration note including safe inventory and uninstall checklist.
- Produce evidence under `.omo/evidence/` for each implementation todo.

### Must NOT have (guardrails, anti-slop, scope boundaries)
- Must not leave active product config references to `nix-homebrew`, `homebrew`, `Homebrew`, `brew-pin-update`, Homebrew taps, casks, MAS, or `/opt/homebrew` PATH injection.
- Must not run the Homebrew uninstall script, delete `/opt/homebrew`, or use cask `zap` during implementation.
- Must not use Homebrew to install replacements.
- Must not introduce new dependencies/third-party flakes/local binary derivations for Helium, OmniWM, Stremio, or Sublime unless user overrides the default gap policy.
- Must not run broad `nix flake update`; lockfile changes should be limited to pruning removed Homebrew inputs.
- Must not reformat unrelated files or change Linux behavior.

## Verification strategy
> Zero human intervention for repo verification; destructive system uninstall remains explicitly out of scope.
- Test decision: tests-after + configuration/eval/build checks.
- Evidence root: `.omo/evidence/homebrew-free-darwin/`.
- Baseline proof:
  - `rg -n --hidden -e 'nix-homebrew|homebrew|Homebrew|brewPinUpdate|brew-pin-update|/opt/homebrew|casks\.nix' flake.nix modules docs --glob '!flake.lock'`
  - `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.enable --json`
  - `nix eval .#darwinConfigurations.aarch64-darwin.config.nix-homebrew.enable --json`
- Post-change proof:
  - `rg -n --hidden -e 'nix-homebrew|homebrew|Homebrew|brewPinUpdate|brew-pin-update|/opt/homebrew|casks\.nix' flake.nix modules docs --glob '!flake.lock'` should return no active product-config hits except intentional migration-note text if accepted.
  - `nix eval .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath --raw`
  - `nix build .#darwinConfigurations.aarch64-darwin.system --no-link`
  - `nix flake check` if runtime cost is acceptable; otherwise record why eval/build is the chosen proof.
  - `git diff --check`
  - Package assertions for new replacements, e.g. `nix eval --expr 'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin; in pkgs.ast-grep.version' --raw` and equivalent for selected attrs.

## Execution strategy
### Parallel execution waves
- Wave 1: Baseline evidence and package availability proof. No edits.
- Wave 2: Independent mechanical edits: flake graph, Darwin Homebrew block/casks/docs, shared PATH/helper cleanup, package replacement list.
- Wave 3: Lockfile prune and integrated eval/build checks.
- Wave 4: Migration note, final audit, and review.

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1 | none | 2, 3, 4, 5 | none |
| 2 | 1 | 6 | 3, 4, 5 |
| 3 | 1 | 6 | 2, 4, 5 |
| 4 | 1 | 6 | 2, 3, 5 |
| 5 | 1 | 6 | 2, 3, 4 |
| 6 | 2, 3, 4, 5 | 7 | none |
| 7 | 6 | final verification | none |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->
- [ ] 1. Capture failing baseline and replacement availability
  What to do / Must NOT do: Create `.omo/evidence/homebrew-free-darwin/`; capture current active Homebrew references, current `homebrew.enable`/`nix-homebrew.enable` evals, current cask/brew/MAS eval summaries, and read-only `brew` inventory if `brew` exists. Verify candidate attrs for `ast-grep`, `mcp-nixos`, `iterm2`, `postman`, `raycast`, `obsidian`, `vesktop`, `ghostty-bin`, and optionally `aerospace`. Must NOT edit product config.
  Parallelization: Wave 1 | Blocked by: none | Blocks: 2, 3, 4, 5
  References (executor has NO interview context - be exhaustive): `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:7-25`, `.omo/ultraresearch/20260630-111142-homebrew-free/verify-current-homebrew-and-nixpkg-coverage.md:13-26`, `flake.nix:11-44`, `flake.nix:395-418`, `modules/darwin/home-manager.nix:20-40`, `modules/darwin/casks.nix:1-29`, `modules/shared/packages.nix:116-223`, `modules/shared/home-manager.nix:97-99`, `modules/shared/home-manager.nix:195-197`, `modules/shared/home-manager.nix:317-320`
  Acceptance criteria (agent-executable): Evidence file contains command, exit code, and output for the baseline grep and evals; attr evals return versions/names for selected replacements; no non-`.omo/evidence` product changes in `git diff --stat`.
  QA scenarios (name the exact tool + invocation): happy: `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.enable --json` returns current baseline `true`; failure: if `brew` is absent, record `command -v brew` failure as acceptable and continue. Evidence `.omo/evidence/homebrew-free-darwin/task-1-baseline.md`.
  Commit: N | evidence only

- [ ] 2. Remove Homebrew/nix-homebrew from the flake graph and lockfile
  What to do / Must NOT do: Delete `nix-homebrew`, `homebrew-bundle`, `homebrew-core`, `homebrew-cask`, and `barutsrb-homebrew-tap` inputs from `flake.nix`; remove them from the `outputs` argument set; remove `nix-homebrew.darwinModules.nix-homebrew` and the inline `nix-homebrew = { ... };` module from `darwinConfigurations`; run lockfile pruning without broad dependency updates. Must NOT remove unrelated inputs or update nixpkgs/home-manager/darwin.
  Parallelization: Wave 2 | Blocked by: 1 | Blocks: 6
  References (executor has NO interview context - be exhaustive): `flake.nix:11-44`, `flake.nix:395-418`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:43-49`, `.omo/ultraresearch/20260630-111142-homebrew-free/wave-2-codebase-implementation-shape-local.md:3-11`
  Acceptance criteria (agent-executable): `rg -n 'nix-homebrew|homebrew-bundle|homebrew-core|homebrew-cask|barutsrb-homebrew-tap' flake.nix flake.lock` returns no hits after lock pruning; `nix flake metadata --json >/dev/null` succeeds.
  QA scenarios (name the exact tool + invocation): happy: `nix flake lock` or equivalent lock regeneration prunes only removed Homebrew-related nodes; failure: `git diff flake.lock` is inspected and any unrelated input updates are reverted. Evidence `.omo/evidence/homebrew-free-darwin/task-2-flake-prune.md`.
  Commit: Y | chore(darwin): remove Homebrew flake graph

- [ ] 3. Remove nix-darwin Homebrew module payload and cask workflow
  What to do / Must NOT do: Delete the `homebrew = { ... };` block from `modules/darwin/home-manager.nix`; delete `modules/darwin/casks.nix` once no references remain; update `modules/darwin/README.md` to remove the cask entry and describe Nix-managed Darwin packages/apps; replace or delete `docs/service-notes/nix-homebrew.md` so it no longer instructs `brew-pin-update`. Must NOT leave empty `homebrew` config for cleanup.
  Parallelization: Wave 2 | Blocked by: 1 | Blocks: 6
  References (executor has NO interview context - be exhaustive): `modules/darwin/home-manager.nix:20-40`, `modules/darwin/casks.nix:1-29`, `modules/darwin/README.md:2-11`, `docs/service-notes/nix-homebrew.md:1-22`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:45-50`
  Acceptance criteria (agent-executable): `test ! -e modules/darwin/casks.nix`; `rg -n 'homebrew|Homebrew|casks\.nix|masApps|brew-pin-update' modules/darwin docs --glob '!*.md'` returns no product-config hits; documentation only contains migration wording, not active update workflow instructions.
  QA scenarios (name the exact tool + invocation): happy: `nix eval .#darwinConfigurations.aarch64-darwin.config.homebrew.enable --json` fails with missing option or returns non-true; failure: any `config.nix-homebrew.taps` reference fails grep and is removed. Evidence `.omo/evidence/homebrew-free-darwin/task-3-darwin-homebrew-removal.md`.
  Commit: Y | chore(darwin): retire cask management

- [ ] 4. Remove Homebrew PATH and helper assumptions from shared modules
  What to do / Must NOT do: Remove `brewPinUpdate` definition and package-list entry from `modules/shared/packages.nix`; remove `/opt/homebrew/bin` and `/opt/homebrew/sbin` PATH prepends from bash/fish/zsh in `modules/shared/home-manager.nix`; remove `/opt/homebrew` from `omxLauncher` shell/module lookup and error message unless a documented non-Homebrew fallback exception is required. Must NOT remove `/usr/local/bin/zsh` unless separately justified; `/usr/local` is not necessarily Homebrew-only.
  Parallelization: Wave 2 | Blocked by: 1 | Blocks: 6
  References (executor has NO interview context - be exhaustive): `modules/shared/packages.nix:5-69`, `modules/shared/packages.nix:116-223`, `modules/shared/packages.nix:357-359`, `modules/shared/home-manager.nix:97-99`, `modules/shared/home-manager.nix:195-197`, `modules/shared/home-manager.nix:226-229`, `modules/shared/home-manager.nix:317-320`, `.omo/ultraresearch/20260630-111142-homebrew-free/wave-2-codebase-implementation-shape-local.md:8-10`
  Acceptance criteria (agent-executable): `rg -n '/opt/homebrew|brewPinUpdate|brew-pin-update|Homebrew completions|nix-homebrew' modules/shared` returns no active hits, except a consciously retained non-PATH comment only if justified in evidence.
  QA scenarios (name the exact tool + invocation): happy: `nix eval .#darwinConfigurations.aarch64-darwin.config.home-manager.users.mei.programs.zsh.enable --json` succeeds after edits; failure: if `omxLauncher` no longer finds a sidecar path in eval, keep Nix sidecar path and non-Homebrew global candidates only. Evidence `.omo/evidence/homebrew-free-darwin/task-4-shared-cleanup.md`.
  Commit: Y | chore(shell): drop Homebrew assumptions

- [ ] 5. Add verified Nix replacements and document gap apps
  What to do / Must NOT do: Add missing direct replacements to the appropriate package lists. Default: add `ast-grep` and `mcp-nixos` to shared or Darwin package scope as appropriate; add Darwin GUI replacements (`iterm2`, `postman`, `raycast`, `obsidian`, `vesktop`, `ghostty-bin`) to Darwin user packages if preserving the cask app set. Keep already-present replacements (`claude-code`, `codex`, `zed-editor`, CLI leaves, fonts) without duplication. Document Helium/OmniWM/Stremio/Sublime as gap apps with manual/vendor/future local-package options. Do not add third-party flakes or local binary derivations for gap apps.
  Parallelization: Wave 2 | Blocked by: 1 | Blocks: 6
  References (executor has NO interview context - be exhaustive): `modules/shared/packages.nix:342-419`, `modules/darwin/packages.nix:1-14`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:20-35`, `.omo/ultraresearch/20260630-111142-homebrew-free/verify-current-homebrew-and-nixpkg-coverage.md:18-26`
  Acceptance criteria (agent-executable): `nix eval` attr checks for each new package return a version/name; `nix eval .#darwinConfigurations.aarch64-darwin.config.home-manager.users.mei.home.packages --json` or equivalent package closure eval succeeds; gap apps are present only in migration documentation, not in active Homebrew/cask config.
  QA scenarios (name the exact tool + invocation): happy: `nix eval --impure --expr 'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.aarch64-darwin; in [ pkgs.ast-grep.name pkgs.mcp-nixos.name pkgs.ghostty-bin.name ]' --json` succeeds; failure: if one GUI attr is unavailable on the current pin, omit that attr, record it in the gap list, and keep the build green. Evidence `.omo/evidence/homebrew-free-darwin/task-5-nix-replacements.md`.
  Commit: Y | feat(darwin): replace casks with Nix packages

- [ ] 6. Integrated eval/build and active-reference audit
  What to do / Must NOT do: Run full post-change grep, eval, build, and diff hygiene. Resolve failures minimally. Must NOT weaken the grep by excluding product files; only exclude `flake.lock` where lock churn is separately audited and allow migration-note docs intentionally.
  Parallelization: Wave 3 | Blocked by: 2, 3, 4, 5 | Blocks: 7
  References (executor has NO interview context - be exhaustive): `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:52-73`, `.omo/ultraresearch/20260630-111142-homebrew-free/wave-2-codebase-implementation-shape-local.md:18-22`
  Acceptance criteria (agent-executable): `nix eval .#darwinConfigurations.aarch64-darwin.config.system.build.toplevel.drvPath --raw` succeeds; `nix build .#darwinConfigurations.aarch64-darwin.system --no-link` succeeds; `git diff --check` succeeds; active-reference grep has no forbidden product-config hits; if `nix flake check` is skipped, evidence records runtime/cost reason.
  QA scenarios (name the exact tool + invocation): happy: build succeeds and grep clean; failure: any remaining Homebrew reference is classified as product-config blocker, migration-doc allowed reference, or research artifact outside implementation scope. Evidence `.omo/evidence/homebrew-free-darwin/task-6-integrated-verify.md`.
  Commit: Y | test(darwin): verify Homebrew-free build

- [ ] 7. Prepare post-switch migration checklist without uninstalling Homebrew
  What to do / Must NOT do: Finalize docs/evidence explaining how to inventory existing Homebrew state, switch to Nix config, verify `/Applications/Nix Apps` or Home Manager app bundles, repin Dock aliases, and only then manually uninstall Homebrew if desired. Must NOT execute the uninstall script or delete cask data.
  Parallelization: Wave 4 | Blocked by: 6 | Blocks: final verification
  References (executor has NO interview context - be exhaustive): `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:48-50`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:62-72`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:80-84`
  Acceptance criteria (agent-executable): Migration note includes `brew list --cask`, `brew leaves --installed-on-request`, `brew services list`, optional `brew bundle dump`, Nix app bundle checks, and explicit “do not zap if preserving data” warning; `rg -n 'zap|uninstall.sh|/opt/homebrew' docs modules` shows these only in migration checklist context, not active config.
  QA scenarios (name the exact tool + invocation): happy: docs are internally consistent with final package list; failure: if docs mention a package that was not actually added, update docs or package list before final. Evidence `.omo/evidence/homebrew-free-darwin/task-7-migration-note.md`.
  Commit: Y | docs(darwin): add Homebrew-free migration checklist

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.
- [ ] F1. Plan compliance audit: verify every Must have / Must NOT have item above against `git diff`, grep output, and evidence files.
- [ ] F2. Code quality review: inspect Nix changes for small diffs, deletion preference, no duplicated package entries, no unrelated formatting churn, and no Linux regressions.
- [ ] F3. Real manual QA: agent-executed local checks only before switch: eval/build, package attr evals, app bundle path expectations; after user explicitly switches, verify app launch/Spotlight/Dock behavior from Nix-owned bundle paths.
- [ ] F4. Scope fidelity: ensure gap apps are not hidden Homebrew dependencies and physical Homebrew uninstall was not run automatically.

## Commit strategy
Prefer 4-5 atomic commits after verification, each using the Lore protocol:
1. Remove flake-level Homebrew wiring and prune lockfile.
2. Remove Darwin Homebrew/cask module payload and docs.
3. Remove shared Homebrew PATH/helper assumptions.
4. Add Nix replacement packages.
5. Add/adjust migration checklist and evidence docs if substantial.

Example commit intent line: `Stop requiring Homebrew for Darwin activation`.
Required trailers for final commit(s): `Constraint: Strict no-Homebrew target`, `Rejected: Keep empty Homebrew module | still requires brew semantics and stale pins`, `Tested: <eval/build/grep evidence>`, `Not-tested: physical Homebrew uninstall not executed`.

## Success criteria
- `flake.nix` and active modules contain no Homebrew/nix-homebrew integration.
- `flake.lock` no longer contains Homebrew/nix-homebrew nodes.
- Active product config has no `/opt/homebrew` PATH injection, `brew-pin-update`, casks, Homebrew taps, or MAS/Homebrew payload.
- Darwin eval and build succeed for `aarch64-darwin`.
- Direct replacement packages are Nix-managed or deliberately documented as deferred gaps.
- Migration documentation makes the destructive Homebrew uninstall an explicit post-switch user action, not an implementation side effect.
