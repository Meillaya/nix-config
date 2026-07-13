---
slug: homebrew-free-darwin
status: awaiting-approval
intent: clear
pending-action: approve .omo/plans/homebrew-free-darwin.md before implementation
approach: strict repo-level Homebrew removal first; Nix replacements for packages already available in the pinned Darwin package set; gap apps documented/deferred instead of keeping casks
---

# Draft: homebrew-free-darwin

## Components (topology ledger)
| id | outcome (one line) | status | evidence path |
| --- | --- | --- | --- |
| C1-flake-inputs | Darwin flake graph no longer imports `nix-homebrew` or pinned Homebrew taps. | active | `flake.nix:11-44`, `flake.nix:395-418`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:43-49` |
| C2-darwin-homebrew-module | nix-darwin `homebrew` option subtree and cask file disappear from product config. | active | `modules/darwin/home-manager.nix:20-40`, `modules/darwin/casks.nix:1-29` |
| C3-path-and-helper-cleanup | Shell startup and repo helpers no longer assume `/opt/homebrew` or expose `brew-pin-update`. | active | `modules/shared/packages.nix:5-69`, `modules/shared/packages.nix:116-223`, `modules/shared/packages.nix:357-359`, `modules/shared/home-manager.nix:97-99`, `modules/shared/home-manager.nix:195-197`, `modules/shared/home-manager.nix:317-320` |
| C4-nix-replacements | Directly available Nix replacements are installed from Nix, not Homebrew. | active | `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:20-25`, `modules/shared/packages.nix:375-419`, `modules/darwin/packages.nix:1-14` |
| C5-gap-policy | Helium, OmniWM, Stremio, and Sublime are not silently retained through Homebrew. | active | `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:27-35`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:80-84` |
| C6-runtime-migration | Homebrew uninstall remains an explicit post-switch action, not an automatic repo edit side effect. | active | `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:48-50`, `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:62-72` |

## Open assumptions (announced defaults)
| assumption | adopted default | rationale | reversible? |
| --- | --- | --- | --- |
| Gap app policy | Do not add third-party flakes or local binary derivations for Helium, OmniWM, Stremio, or Sublime in the first implementation pass. Document them as manual/vendor/future-packaging follow-up. | This satisfies strict zero Homebrew without introducing new trust, license, hash, or runtime-maintenance surfaces. | Yes; add one app package at a time later. |
| Direct replacement set | Add current-pinned Nix attrs for `ast-grep`, `mcp-nixos`, and Darwin GUI/app replacements that evaluated successfully (`iterm2`, `postman`, `raycast`, `obsidian`, `vesktop`, `ghostty-bin`). Do not configure a window manager replacement automatically. | Research and local eval show these are available; adding packages is less risky than third-party app packaging. | Yes; individual package entries can be removed. |
| Aerospace | Treat `aerospace` as optional package-only follow-up unless explicitly desired. | It is a functional OmniWM alternative but enabling/configuring a WM changes interaction behavior beyond “remove Homebrew.” | Yes. |
| Homebrew uninstall | Do not run the Homebrew uninstall script during repo implementation. Produce inventory/checklist evidence and leave uninstall as an explicit user action after Nix switch proves replacements. | Deleting `/opt/homebrew` is destructive and machine-stateful. | Yes; user can run later. |
| Docs | Replace the Homebrew update workflow doc with a no-Homebrew migration note instead of leaving historical operational instructions. | Avoids stale instructions to run `brew-pin-update`. | Yes. |

## Findings (cited - path:lines)
- Repo currently declares `nix-homebrew`, Homebrew tap inputs, and Homebrew tap output args in `flake.nix:11-44`.
- Darwin systems import `nix-homebrew.darwinModules.nix-homebrew` and enable pinned taps in `flake.nix:395-418`.
- nix-darwin Homebrew payload is enabled from `modules/darwin/home-manager.nix:20-40` and casks are listed in `modules/darwin/casks.nix:1-29`.
- Shell/launcher/helper Homebrew coupling remains in `modules/shared/packages.nix:5-69`, `modules/shared/packages.nix:116-223`, `modules/shared/packages.nix:357-359`, `modules/shared/home-manager.nix:97-99`, `modules/shared/home-manager.nix:195-197`, and `modules/shared/home-manager.nix:317-320`.
- Ultraresearch verified the current repo eval as `homebrew.enable = true`, `nix-homebrew.enable = true`, 12 casks, no brews, and no MAS apps in `.omo/ultraresearch/20260630-111142-homebrew-free/verify-current-homebrew-and-nixpkg-coverage.md:13-17`.
- Local package coverage verified direct Nix replacements and identified remaining app gaps in `.omo/ultraresearch/20260630-111142-homebrew-free/verify-current-homebrew-and-nixpkg-coverage.md:18-26`.
- Recommended migration sequence and verification commands are summarized in `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md:43-73`.

## Decisions (with rationale)
1. Remove Homebrew completely from the declarative config instead of keeping an empty Homebrew module. Rationale: strict “no Homebrew” target; nix-darwin Homebrew module requires an existing `brew` binary when enabled.
2. Prune Homebrew flake inputs and lock nodes instead of leaving unused pins. Rationale: avoids stale tap update workflow and reduces eval surface.
3. Remove `/opt/homebrew` from shell PATH and OMX launcher fallback. Rationale: zero-Homebrew means startup should not prefer or advertise Homebrew global installs.
4. Add available Nix packages for current cask/formula leaves where low-risk and pinned-eval verified. Rationale: preserve the bulk of current user capabilities without Homebrew.
5. Defer Helium/OmniWM/Stremio/Sublime packaging. Rationale: they need vendor/manual/local/third-party packaging decisions and should not force new trust/dependency surfaces into the first removal pass.
6. Keep uninstall of the physical Homebrew tree out of automated implementation. Rationale: destructive machine operation; inventory first and run only after Nix switch QA passes.

## Scope IN
- Product config edits to remove Homebrew/nix-homebrew references and packages.
- `flake.lock` cleanup for removed Homebrew inputs.
- Package-list additions for verified Nix replacements.
- Docs update replacing the nix-homebrew update workflow with a Homebrew-free migration/uninstall checklist.
- Agent-executed eval/build/grep verification and best-effort read-only Homebrew inventory.

## Scope OUT (Must NOT have)
- No Homebrew casks, formulae, taps, MAS, `nix-homebrew`, `brew-pin-update`, or `/opt/homebrew` PATH injection in active product config.
- No third-party Helium flake or local binary derivations in this first pass.
- No automatic `/opt/homebrew` deletion or Homebrew uninstall script execution.
- No unrelated flake input updates, dependency churn, formatting rewrites, or GUI/window-manager behavior changes.

## Open questions
- Only sanity-check question: accept the default gap policy (remove Helium/OmniWM/Stremio/Sublime from declarative management for now, with documentation and future packaging hooks), or choose a package-now path for one or more of them before implementation?

## Approval gate
status: awaiting-approval
Approve `.omo/plans/homebrew-free-darwin.md` to implement the strict repo-level Homebrew removal with the default gap policy above. If you want Helium, OmniWM, Stremio, or Sublime packaged in this same pass, name those apps first because that changes dependency/trust scope.
