# AI tooling declarative boundary

This repo now declares package presence for the nixpkgs-available tools:

- `codex`
- `claude-code`
- `ollama`

It also tracks safe local config files for:

- Codex (`.codex/config.toml`, `.codex/hooks.json`, `.codex/AGENTS.md`)
- OMX HUD config (`.omx/hud-config.json`)
- OpenCode (`.config/opencode/opencode.json`)

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
