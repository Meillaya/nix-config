<analysis>
Core question: The user wants to stop using Homebrew entirely on a macOS nix-darwin system. Determine every repo-level Homebrew touchpoint, whether nix-darwin Homebrew integration is active, what Nix-native replacements exist for current casks/brews/Mac App Store apps, what cannot be replaced cleanly, and a safe migration/uninstall sequence.
Axes (orthogonal):
1. Repo Homebrew surface — search nix-darwin modules, flake inputs, README, overlays, history for homebrew/brew/cask/mas/app-store references and current option wiring.
2. nix-darwin semantics — verify current nix-darwin homebrew module behavior, option names, activation assumptions, and whether disabling module is sufficient.
3. Nixpkgs/nix-darwin replacement coverage — map casks/brews/mas entries to Nix packages, darwin Apps mechanisms, fonts, LaunchServices, and home-manager alternatives.
4. macOS uninstall/migration risk — what remains after nix-darwin stops managing Homebrew, how to remove /opt/homebrew safely, and how to preserve app data.
5. Real-world examples — examine public nix-darwin repos/issues for Homebrew-free patterns and caveats on GUI apps.
6. Verification — evaluate current flake/darwin config with nix tooling where possible and produce grep/history evidence.
Codebase relevant: yes · External: yes · Browsing: yes · Verification likely: yes · Report requested: no, synthesis markdown only
</analysis>
