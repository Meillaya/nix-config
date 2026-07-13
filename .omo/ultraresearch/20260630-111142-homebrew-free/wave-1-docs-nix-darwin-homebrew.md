# Wave 1: nix-darwin Homebrew module semantics

Worker: researcher `019f1916-916d-7d22-8455-426c7ef4c900`

## Key findings
- `homebrew.enable = true` enables nix-darwin's Homebrew Bundle integration; it does not install Homebrew.
- Activation runs `brew bundle` as sudo for the configured user.
- Default activation does not auto-update, upgrade, or clean extra packages.
- `homebrew.onActivation.cleanup` supports `none`, `check`, `uninstall`, and `zap`.
- `homebrew.masApps` removals are not automatically uninstalled even when cleanup is `uninstall` or `zap`.
- Fully Homebrew-free final state should remove the entire `homebrew` subtree and any `nix-homebrew` flake/module wiring.
- Optional temporary cleanup phase: keep Homebrew enabled with empty lists and cleanup `uninstall`/`zap`, switch once, then remove the module entirely.

## Sources
- https://nix-darwin.github.io/nix-darwin/manual/
- https://github.com/nix-darwin/nix-darwin/blob/master/modules/homebrew.nix
- https://github.com/nix-darwin/nix-darwin/blob/master/CHANGELOG
- https://docs.brew.sh/Installation
- https://docs.brew.sh/Manpage
- https://docs.brew.sh/Brew-Bundle-and-Brewfile
- https://docs.brew.sh/Tap-Trust

## EXPAND markers verbatim
- LEAD: current nix-darwin Homebrew option surface — WHY: verify whether any new homebrew options landed after the 2026-02-10 changelog entry — ANGLE: re-read the latest manual and `modules/homebrew.nix` for diffs around `options.homebrew`
- LEAD: Homebrew Bundle cleanup semantics — WHY: confirm whether `check/uninstall/zap` behavior changed upstream — ANGLE: re-check docs.brew.sh/Manpage and Brew-Bundle docs around cleanup/trust handling
- LEAD: migration-to-homebrew-free path — WHY: ensure no Homebrew-installed residue remains after disabling the module — ANGLE: inspect whether MAS apps or tap trusts require manual removal outside nix-darwin
