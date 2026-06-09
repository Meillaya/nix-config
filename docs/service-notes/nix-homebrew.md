# nix-homebrew update workflow

On Darwin, Homebrew is pinned and managed by `nix-homebrew`, so `brew update`
is expected to fail when it tries to mutate tap repos inside `/nix/store`.

Use the repo helper instead:

```bash
brew-pin-update codex
brew-pin-update claude-code
brew-pin-update --reinstall codex
brew-pin-update --formula ripgrep
```

What it does:

1. updates the relevant flake input (`homebrew-cask` by default, or
   `homebrew-core` with `--formula`)
2. runs `nix run .#build-switch`
3. upgrades or reinstalls the requested Homebrew package

This keeps Homebrew package updates aligned with the repo's pinned tap state.
