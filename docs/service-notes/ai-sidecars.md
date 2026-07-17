# Nix-owned AI command boundary

Home Manager owns the `codex`, `omx`, `opencode`, and optional `omc` commands.
Their executable payloads are immutable Nix store paths; activation never runs
npm, Homebrew, a self-updater, or `nix profile` to install software.

`omx` sets `OMX_AUTO_UPDATE=0` and executes only the pinned
`oh-my-codex-sidecar` payload. `omc` likewise prefers its pinned terminal
sidecar. Authentication, history, transcripts, caches, plugin state, and the
user-editable Codex/Claude configuration remain writable in the home directory.

Home Manager seeds these files only when they are absent or still an old store
symlink:

- `~/.codex/config.toml`
- `~/.codex/hooks.json`
- `~/.codex/AGENTS.md`
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.omx/hud-config.json`

Credentials and runtime state are deliberately not tracked. Do not install a
second copy of these commands globally with npm, Homebrew, or a Nix profile;
that would make command ownership and rollback ambiguous.
