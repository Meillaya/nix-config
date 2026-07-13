# Wave 1: official Nix flake/update semantics

Worker: Pascal (`019f1bf9-6e5e-74d1-b038-d49824bb32ad`)

## Key findings
- Flake inputs are declared in `flake.nix`; `flake.lock` pins those inputs.
- `nix flake update` updates `flake.lock`, all inputs by default or named inputs explicitly.
- `nix flake lock` adds missing entries without updating existing ones.
- Inline fixed-output hashes in Nix expressions are separate from lockfile hashes; official docs do not indicate that flake commands rewrite inline hash literals.
- Flake apps are execution entrypoints; `nix run` does not manage/update hashes.
- Flakes may ignore untracked files; local new package/update files should be tracked/staged for flake evaluation.

## Sources returned
- Nix flake manual: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake.html
- Nix flake update manual: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-flake-update.html
- Builtins manual: https://nix.dev/manual/nix/2.34/language/builtins.html
- nix-prefetch-url manual: https://nix.dev/manual/nix/2.34/command-ref/nix-prefetch-url.html
- nix derivation show: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-derivation-show.html
- nix run: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-run.html
- nix flake check: https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-flake-check
- Flakes concepts: https://nix.dev/concepts/flakes.html
- Packaging tutorial: https://nix.dev/tutorials/packaging-existing-software.html

## EXPAND markers verbatim
- LEAD: flake input graph / lock-file semantics — WHY: determines the exact scope of `nix flake update` — ANGLE: `nix flake` manual sections on `inputs`, `flake.lock`, and `locked` fetchTree args
- LEAD: update-command behavior — WHY: confirms what gets rewritten and when lock files are created — ANGLE: dedicated `nix flake update` page
- LEAD: fixed-output fetchers and hashes — WHY: distinguishes lock-file hashes from inline `sha256`/`narHash` literals — ANGLE: `builtins.fetchTarball`, `builtins.fetchTree`, `nix-prefetch-url`, `nix derivation show`, and the `fetchzip`/`fetchFromGitHub` tutorial
- LEAD: flake app caveats — WHY: clarifies what apps can and cannot do — ANGLE: `nix run`, `nix flake check`, and nix.dev flake concepts
- LEAD: tracked-file caveat — WHY: flake evaluation can ignore unstaged local changes — ANGLE: nix.dev flake concepts page (`builds only tracked files`, `files must be staged`)
