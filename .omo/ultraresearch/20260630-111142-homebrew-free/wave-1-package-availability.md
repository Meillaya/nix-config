# Wave 1 — Package availability evidence

Local verification: `nix search nixpkgs <name> --json` and `nix eval` on aarch64-darwin, Nix 2.34.6, <nixpkgs> snapshot in current environment.

Available direct replacements: claude-code, claude-code-bin, codex, iterm2, postman, raycast, obsidian, vesktop, zed-editor, aerospace, yabai, skhd, jankyborders, jetbrains-mono, nerd-fonts.jetbrains-mono.

Not good/direct replacements: helium-browser not found; omniwm/barutsrb tap not found; stremio-linux-shell is Linux-only; sublime* in nixpkgs is Linux-only despite searchable attributes.

Alternative candidates found: bruno, insomnia, hoppscotch for Postman-like API work; discord for Vesktop if alternate client is not required; aerospace/yabai/skhd/jankyborders for OmniWM-ish window-management stack; Rectangle, alt-tab-macos, maccy, sketchybar for macOS GUI utilities.
