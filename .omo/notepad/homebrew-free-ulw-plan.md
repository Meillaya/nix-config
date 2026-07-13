# Notepad: homebrew-free ulw-plan

## Skill survey
- `omo:ulw-plan`: active; user explicitly invoked it; planner-only, writes `.omo` plan artifacts and never implements.
- `omo:programming`: not active for edits because this turn is planning-only and no `.nix` product code is being modified; plan will mention Nix verification commands.
- `omo:refactor` / `omo:remove-ai-slops`: skipped; this is not cleanup/refactor implementation, only migration planning.
- `omo:git-master`: skipped; no commit requested, but plan will include commit guidance.
- `omo:review-work`: skipped now; plan will include review/QA gates for execution.

## Tier triage
HEAVY — multi-module nix-darwin migration touching flake inputs, lockfile, Darwin modules, shared shell startup, package sets, docs, and external app/package decisions.

## Binding success criteria
1. User-visible deliverable: one decision-complete `.omo/plans/<slug>.md` for strict no-Homebrew migration, plus durable draft, with no product-code changes.
2. Plan must use the saved ultraresearch synthesis as evidence and spell out exact file surfaces, package defaults, must-not-haves, QA commands, and stop conditions.
3. Plan must leave zero implementation judgment calls except explicitly marked future/out-of-scope app packaging follow-ups.

## Manual-QA / evidence channel for this planning task
- Data/CLI-shaped surface: verify plan artifact with `test -f`, `rg` required sections, and `sed` review snippets.
- PASS observable: plan file exists, contains TL;DR, Todos, exact file paths, QA commands, Must-NOT-Have, and approval gate; no product code diff beyond `.omo` artifacts.

## Status
- Bootstrap started.

## Intent routing
CLEAR — user pasted a completed ultraresearch synthesis and the desired outcome is strict no-Homebrew nix-darwin migration. Open items are implementation policy/tradeoff decisions, not outcome discovery.

## Components ledger
- C1 Flake/Homebrew module removal — remove nix-homebrew/Homebrew inputs, module wiring, cask block, lock roots; status grounded; evidence `.omo/ultraresearch/20260630-111142-homebrew-free/SYNTHESIS.md`.
- C2 Package replacement set — keep/add Nix packages for casks/leaves (`ast-grep`, `mcp-nixos`, `ghostty-bin`, `aerospace` optional); status grounded by local eval in synthesis.
- C3 Shell/helper cleanup — remove `/opt/homebrew` path injections and `brew-pin-update`; status grounded.
- C4 Docs/migration receipts — update Darwin README and retire nix-homebrew service note; status grounded.
- C5 Runtime QA/uninstall handoff — verify Nix apps and only then uninstall Homebrew; status grounded.
- C6 Gap-app policy — Helium/OmniWM/Stremio/Sublime need owner policy; status pending user approval/default.

## Candidate owner decision
Gap apps without direct nixpkgs Darwin attrs can be handled by: recommended default A) exclude from first implementation and document as manual/vendor/local-packaging follow-up while removing Homebrew entirely; B) add third-party/local package derivations now; C) keep Homebrew temporarily for them (conflicts with strict zero Homebrew).
