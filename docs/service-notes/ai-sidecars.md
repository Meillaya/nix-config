# oh-my sidecars: install and config boundary

This repo now provides:

- `omx` wrapper for `oh-my-codex`
- `omc` wrapper for `oh-my-claude-sisyphus`
- `sync-ai-sidecars` helper to install pinned sidecar versions locally

Pinned helper versions:

- `oh-my-codex@0.14.4`
- `oh-my-claude-sisyphus@4.13.3`

## Install/update the sidecars

```bash
sync-ai-sidecars
```

Or explicitly:

```bash
AI_SIDECAR_PREFIX=$HOME/.local sync-ai-sidecars
```

This installs the npm packages into the expected local prefix so the repo's
managed wrappers and config keep working without hand-managed global installs.

## Safe config now tracked

- `~/.claude/.omc-config.json`
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.codex/config.toml` baseline, installed as a writable file
- `~/.codex/hooks.json` baseline, installed as a writable file
- `~/.codex/AGENTS.md` baseline, installed as a writable file
- `~/.omx/hud-config.json`

`~/.codex/config.toml` is seeded by Home Manager when missing or replacing an
old store symlink, but is not linked directly into `/nix/store`. Codex persists
runtime preferences, such as the default model, by rewriting this file.
`~/.codex/AGENTS.md` follows the same writable-baseline pattern because
`omx setup` regenerates it.
`~/.codex/hooks.json` is also writable because OMX refreshes native hook
coverage during setup.

## Intentionally not tracked

- `~/.claude/.credentials.json`
- `~/.claude/history.jsonl`
- `~/.claude/transcripts/*`
- `~/.claude/plugins/installed_plugins.json`
- `~/.codex/auth.json`
- `~/.codex/history.jsonl`
- `~/.omx/logs/*`
- `~/.omx/state/*`

These contain auth, logs, runtime state, or rapidly changing history.
