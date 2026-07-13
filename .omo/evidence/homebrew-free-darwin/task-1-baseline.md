# Task 1 baseline evidence

## git status
?? .omc/
?? .omo/

## active Homebrew references
docs/service-notes/nix-homebrew.md:1:# nix-homebrew update workflow
docs/service-notes/nix-homebrew.md:3:On Darwin, Homebrew is pinned and managed by `nix-homebrew`, so `brew update`
docs/service-notes/nix-homebrew.md:9:brew-pin-update codex
docs/service-notes/nix-homebrew.md:10:brew-pin-update claude-code
docs/service-notes/nix-homebrew.md:11:brew-pin-update --reinstall codex
docs/service-notes/nix-homebrew.md:12:brew-pin-update --formula ripgrep
docs/service-notes/nix-homebrew.md:17:1. updates the relevant flake input (`homebrew-cask` by default, or
docs/service-notes/nix-homebrew.md:18:   `homebrew-core` with `--formula`)
docs/service-notes/nix-homebrew.md:20:3. upgrades or reinstalls the requested Homebrew package
docs/service-notes/nix-homebrew.md:22:This keeps Homebrew package updates aligned with the repo's pinned tap state.
flake.nix:11:    nix-homebrew = {
flake.nix:12:      url = "github:zhaofengli-wip/nix-homebrew";
flake.nix:14:    homebrew-bundle = {
flake.nix:15:      url = "github:homebrew/homebrew-bundle";
flake.nix:18:    homebrew-core = {
flake.nix:19:      url = "github:homebrew/homebrew-core";
flake.nix:22:    homebrew-cask = {
flake.nix:23:      url = "github:homebrew/homebrew-cask";
flake.nix:26:    barutsrb-homebrew-tap = {
flake.nix:27:      url = "github:BarutSRB/homebrew-tap";
flake.nix:44:  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, barutsrb-homebrew-tap, home-manager, nixpkgs, disko, agenix, zen-browser, noctalia } @inputs:
flake.nix:401:            nix-homebrew.darwinModules.nix-homebrew
flake.nix:403:              nix-homebrew = {
flake.nix:407:                  "homebrew/homebrew-core" = homebrew-core;
flake.nix:408:                  "homebrew/homebrew-cask" = homebrew-cask;
flake.nix:409:                  "homebrew/homebrew-bundle" = homebrew-bundle;
flake.nix:410:                  "BarutSRB/homebrew-tap" = barutsrb-homebrew-tap;
modules/darwin/README.md:6:├── casks.nix          # List of homebrew casks
modules/shared/packages.nix:13:        /opt/homebrew/bin/zsh \
modules/shared/packages.nix:41:      /opt/homebrew/lib/node_modules/oh-my-codex \
modules/shared/packages.nix:68:    echo "Expected oh-my-codex under npm global packages, /opt/homebrew, or /opt/zerobrew." >&2
modules/shared/packages.nix:116:  brewPinUpdate = writeShellScriptBin "brew-pin-update" ''
modules/shared/packages.nix:121:Usage: brew-pin-update [--formula] [--reinstall] <package> [package...]
modules/shared/packages.nix:123:Update this repo's nix-homebrew pin(s), rebuild the Darwin config, then upgrade
modules/shared/packages.nix:124:the requested Homebrew package(s).
modules/shared/packages.nix:126:Defaults to casks. Use --formula for Homebrew formulae.
modules/shared/packages.nix:129:  brew-pin-update codex
modules/shared/packages.nix:130:  brew-pin-update claude-code
modules/shared/packages.nix:131:  brew-pin-update --reinstall codex
modules/shared/packages.nix:132:  brew-pin-update --formula ripgrep
modules/shared/packages.nix:137:      echo "brew-pin-update only supports Darwin hosts managed by nix-homebrew." >&2
modules/shared/packages.nix:146:        echo "brew-pin-update must run from this repo or a git worktree inside it." >&2
modules/shared/packages.nix:188:      echo "brew-pin-update: missing package name" >&2
modules/shared/packages.nix:196:      echo "Updating pinned Homebrew cask input..."
modules/shared/packages.nix:197:      ${nix}/bin/nix flake lock --update-input homebrew-cask
modules/shared/packages.nix:199:      echo "Updating pinned Homebrew core input..."
modules/shared/packages.nix:200:      ${nix}/bin/nix flake lock --update-input homebrew-core
modules/shared/packages.nix:208:        echo "Reinstalling Homebrew cask(s): $*"
modules/shared/packages.nix:209:        /opt/homebrew/bin/brew reinstall --cask "$@"
modules/shared/packages.nix:211:        echo "Upgrading Homebrew cask(s): $*"
modules/shared/packages.nix:212:        /opt/homebrew/bin/brew upgrade --cask "$@"
modules/shared/packages.nix:216:        echo "Reinstalling Homebrew formula(e): $*"
modules/shared/packages.nix:217:        /opt/homebrew/bin/brew reinstall "$@"
modules/shared/packages.nix:219:        echo "Upgrading Homebrew formula(e): $*"
modules/shared/packages.nix:220:        /opt/homebrew/bin/brew upgrade "$@"
modules/shared/packages.nix:358:  brewPinUpdate
modules/darwin/home-manager.nix:20:  homebrew = {
modules/darwin/home-manager.nix:22:    taps = builtins.attrNames config.nix-homebrew.taps;
modules/darwin/home-manager.nix:23:    casks = pkgs.callPackage ./casks.nix {};
modules/shared/home-manager.nix:98:      export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
modules/shared/home-manager.nix:196:      fish_add_path --prepend /opt/homebrew/bin /opt/homebrew/sbin
modules/shared/home-manager.nix:228:      # unmanaged Homebrew completions before Powerlevel10k instant prompt.
modules/shared/home-manager.nix:319:        export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH

## nix eval homebrew.enable
true

## nix eval nix-homebrew.enable
true

## nix eval homebrew casks
[{"args":null,"brewfileLine":"cask \"claude-code\"","greedy":null,"name":"claude-code","postinstall":null},{"args":null,"brewfileLine":"cask \"codex\"","greedy":null,"name":"codex","postinstall":null},{"args":null,"brewfileLine":"cask \"iterm2\"","greedy":null,"name":"iterm2","postinstall":null},{"args":null,"brewfileLine":"cask \"postman\"","greedy":null,"name":"postman","postinstall":null},{"args":null,"brewfileLine":"cask \"raycast\"","greedy":null,"name":"raycast","postinstall":null},{"args":null,"brewfileLine":"cask \"obsidian\"","greedy":null,"name":"obsidian","postinstall":null},{"args":null,"brewfileLine":"cask \"helium-browser\"","greedy":null,"name":"helium-browser","postinstall":null},{"args":null,"brewfileLine":"cask \"vesktop\"","greedy":null,"name":"vesktop","postinstall":null},{"args":null,"brewfileLine":"cask \"barutsrb/tap/omniwm\"","greedy":null,"name":"barutsrb/tap/omniwm","postinstall":null},{"args":null,"brewfileLine":"cask \"zed\"","greedy":null,"name":"zed","postinstall":null},{"args":null,"brewfileLine":"cask \"stremio\"","greedy":null,"name":"stremio","postinstall":null},{"args":null,"brewfileLine":"cask \"sublime-text\"","greedy":null,"name":"sublime-text","postinstall":null}]

## package attr availability
ast-grep         0.42.1
mcp-nixos        2.3.1
ghostty-bin      1.3.1
aerospace        0.20.3-Beta
iterm2           3.6.6
postman          11.89.0
raycast          1.104.10
obsidian         1.12.7
vesktop          1.6.5
zed-editor       0.232.2
claude-code      2.1.112
codex            0.121.0

## brew inventory if present
$ brew list --cask
claude-code
codex
font-jetbrains-mono-nerd-font
font-symbols-only-nerd-font
ghostty
helium-browser
iterm2
obsidian
omniwm
postman
raycast
stremio
sublime-text
vesktop
zed
$ brew leaves --installed-on-request
ast-grep
cocoapods
gh
go
helix
micro
neovim
omniorb
python@3.12
uv
zig
$ brew services list
