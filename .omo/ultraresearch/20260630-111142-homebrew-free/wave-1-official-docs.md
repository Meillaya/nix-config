# Wave 1 — Official docs/source findings

Searches/operators used included:
1. `nix-darwin manual environment.systemPackages environment.darwinConfig official`
2. `nix-darwin manual homebrew masApps official options casks brews onActivation cleanup`
3. `Home Manager manual home.packages fonts packages official`
4. `nixpkgs manual package search search.nixos.org packages Darwin macOS`
5. `nix-darwin applications symlink /Applications Nix Apps LaunchServices aliases activation scripts official`
6. `site:github.com/nix-darwin/nix-darwin create /Applications/Nix Apps symlink`
7. `mas-cli README limitations app store sign in official`
8. `nixpkgs darwin cask GUI app codesigning quarantine issue`
9. `site:github.com/NixOS/nixpkgs darwin codesign app bundle quarantine Gatekeeper`
10. `site:nixos.org/manual/nixpkgs autoSignDarwinBinariesHook`
11. `site:search.nixos.org/packages nixpkgs obsidian package`
12. `site:search.nixos.org/packages nixpkgs claude-code package`

Key findings: nix-darwin system packages go to /run/current-system/sw and apps are copied to /Applications/Nix Apps with rsync; HM home.packages are per-user and HM has linkApps/copyApps and font-copy behavior; mas has account/App Store limitations; unfree and unsupported-platform gates matter.
