# AI tooling declarative boundary

This repo now declares package presence for the nixpkgs-available tools:

- `codex`
- `claude-code`
- `ollama`

It also tracks safe local config files for:

- Codex (`.codex/config.toml`, `.codex/hooks.json`, `.codex/AGENTS.md` baselines)
- OMX HUD config (`.omx/hud-config.json`)
- OpenCode (`.config/opencode/opencode.json`)

The Codex `config.toml` baseline is seeded when missing or replacing an old
store symlink. It is kept as a writable file, not a Home Manager store symlink,
because the Codex CLI rewrites it when preferences such as the default model
are saved.
The Codex `AGENTS.md` baseline uses the same writable-file boundary because
`omx setup` regenerates it.
The Codex `hooks.json` baseline is writable for the same reason: OMX refreshes
native hook coverage during setup.

## Not yet declaratively installed via nixpkgs

The following tools are still outside the repo's package declarations because
they currently live as npm/global tooling rather than nixpkgs packages in this
setup:

- `oh-my-codex`
- `oh-my-claude-sisyphus`

## Why some AI state is not committed

These paths contain secrets, auth, logs, or runtime history and are intentionally
excluded from declarative sync:

- `.codex/auth.json`
- `.codex/history.jsonl`
- `.codex/log*`
- `.claude/*` runtime history/state
- `.omx/logs/*`
- `.omx/state/*`
- `.ollama/id_ed25519*`

The current declarative boundary is: package presence plus safe config, but not
auth material, logs, or conversation history.
