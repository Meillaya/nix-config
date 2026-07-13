let
  flake = builtins.getFlake ("path:" + toString ../.);
  nixos = flake.nixosConfigurations."x86_64-linux".config;
  nixosArm = flake.nixosConfigurations."aarch64-linux".config;
  darwin = flake.darwinConfigurations."aarch64-darwin".config;
  darwinIntel = flake.darwinConfigurations."x86_64-darwin".config;
  standalone = flake.homeConfigurations."standalone-linux".config;
  standaloneArm = flake.homeConfigurations."standalone-linux-aarch64".config;
  shellName = shell: shell.pname or shell.name or (builtins.baseNameOf (toString shell));
  expectedLinuxApps = [
    "build-switch" "clean" "home-news" "home-switch" "search-pkgs" "sync-secrets"
    "update"
  ];
  expectedDarwinApps = [
    "build" "build-switch" "check-keys" "clean" "copy-keys" "create-keys"
    "search-pkgs" "update"
  ];
  hasShell = name: shells: builtins.any (shell: shellName shell == name) shells;
  hasInfix = flake.inputs.nixpkgs.lib.hasInfix;
  countExactLine = expected: text:
    builtins.length (
      builtins.filter
        (line: line == expected)
        (flake.inputs.nixpkgs.lib.splitString "\n" text)
    );
  packageName = package: package.pname or package.name or (builtins.baseNameOf (toString package));
  hasPackages = names: packages:
    let present = map packageName packages;
    in builtins.all (name: builtins.elem name present) names;
  requiredLinuxApplications = [
    "calibre" "gimp" "ghostty" "helium" "kitty" "obsidian" "ollama"
    "qbittorrent" "noctalia" "swaybg" "zen-beta"
  ];
  expectedDarwinShellActivation = ''
    desired_shell=/run/current-system/sw/bin/nu
    if [[ ! -x "$systemConfig/sw/bin/nu" ]]; then
      printf >&2 'error: configured Nushell is not executable: %s\n' "$systemConfig/sw/bin/nu"
      exit 1
    fi

    current_shell=$(/usr/bin/dscl . -read /Users/mei UserShell)
    current_shell="''${current_shell#UserShell: }"
    if [[ "$current_shell" != "$desired_shell" ]]; then
      /usr/bin/dscl . -create /Users/mei UserShell "$desired_shell"
    fi
  '';
  assertHm = hm:
    assert hm.programs.nushell.enable;
    assert hm.programs.nushell.settings.show_hints;
    assert hm.programs.nushell.settings.history.file_format == "sqlite";
    assert hm.programs.nushell.settings.history.sync_on_enter;
    assert hm.programs.nushell.settings.completions.algorithm == "fuzzy";
    assert hm.programs.nushell.settings.color_config.hints == "light_cyan";
    assert hasInfix ".nix-profile/bin" hm.programs.nushell.extraEnv;
    assert hasInfix "/run/current-system/sw/bin" hm.programs.nushell.extraEnv;
    assert hasInfix "fastfetch" hm.programs.nushell.extraConfig;
    assert hasInfix "which fastfetch" hm.programs.nushell.extraConfig;
    assert hm.programs.kitty.enable;
    assert hm.programs.kitty.settings.background == "#161925";
    assert hm.programs.kitty.settings.foreground == "#c3c7d1";
    assert hm.programs.kitty.settings.color1 == "#ed254e";
    assert hm.programs.kitty.settings.color2 == "#71f79f";
    assert hasInfix "/bin/nu --login" hm.programs.kitty.settings.shell;
    assert hm.programs.bash.enable;
    assert hm.programs.zsh.enable;
    assert hm.programs.fish.enable;
    assert countExactLine "set -g allow-passthrough on"
      hm.programs.tmux.extraConfig == 1;
    assert countExactLine "set -g allow-passthrough on"
      hm.xdg.configFile."tmux/tmux.conf".text == 1;
    true;
in
assert builtins.attrNames flake.nixosConfigurations == [ "aarch64-linux" "x86_64-linux" ];
assert builtins.attrNames flake.darwinConfigurations == [ "aarch64-darwin" "x86_64-darwin" ];
assert builtins.attrNames flake.homeConfigurations == [ "standalone-linux" "standalone-linux-aarch64" ];
assert builtins.attrNames flake.apps.x86_64-linux == expectedLinuxApps;
assert builtins.attrNames flake.apps.aarch64-darwin == expectedDarwinApps;
assert nixos.networking.hostName == "nixos";
assert nixos.system.stateVersion == "21.05";
assert nixos.programs.niri.enable;
assert nixos.xdg.portal.enable;
assert nixos.services.displayManager.defaultSession == "niri";
assert hasPackages [ "noctalia" ] nixos.environment.systemPackages;
assert hasPackages requiredLinuxApplications (
  nixos.home-manager.users.mei.home.packages ++ nixos.environment.systemPackages
);
assert nixos.systemd.user.services.noctalia.wantedBy == [ "graphical-session.target" ];
assert nixos.systemd.user.services.noctalia.serviceConfig.Restart == "on-failure";
assert hasInfix "/bin/noctalia" nixos.systemd.user.services.noctalia.serviceConfig.ExecStart;
assert !hasInfix ''spawn-at-startup "noctalia"''
  nixos.home-manager.users.mei.home.file."/home/mei/.config/niri/config.kdl".text;
assert nixos.users.users.mei.hashedPasswordFile == "/var/lib/nixos-bootstrap/mei-password.hash";
assert nixos.users.users.mei.isNormalUser;
assert nixos.users.users.mei.home == "/home/mei";
assert builtins.all (group: builtins.elem group nixos.users.users.mei.extraGroups) [
  "wheel"
  "networkmanager"
  "docker"
  "i2c"
  "video"
];
assert shellName nixos.users.users.mei.shell == "nushell";
assert hasShell "nushell" nixos.environment.shells;
assert hasShell "bash" nixos.environment.shells;
assert hasShell "zsh" nixos.environment.shells;
assert hasShell "fish" nixos.environment.shells;
assert assertHm nixos.home-manager.users.mei;
assert assertHm nixosArm.home-manager.users.mei;
assert hasInfix "/bin/nu --login"
  nixos.home-manager.users.mei.home.file."/home/mei/.local/share/konsole/Garuda.profile".text;
assert darwin.system.stateVersion == 5;
assert darwin.system.primaryUser == "mei";
assert shellName darwin.users.users.mei.shell == "nushell";
assert hasShell "nu" darwin.environment.shells;
assert hasShell "bash" darwin.environment.shells;
assert hasShell "zsh" darwin.environment.shells;
assert hasShell "fish" darwin.environment.shells;
assert hasPackages [ "kitty" ] darwin.environment.systemPackages;
assert hasPackages [ "kitty" ] darwinIntel.environment.systemPackages;
assert flake.inputs.nixpkgs.lib.hasSuffix expectedDarwinShellActivation
  darwin.system.activationScripts.postActivation.text;
assert assertHm darwin.home-manager.users.mei;
assert assertHm darwinIntel.home-manager.users.mei;
assert standalone.home.username == "mei";
assert standalone.home.homeDirectory == "/home/mei";
assert standalone.home.stateVersion == "25.11";
assert hasPackages requiredLinuxApplications standalone.home.packages;
assert standalone.systemd.user.services.noctalia.Install.WantedBy == [ "graphical-session.target" ];
assert standalone.systemd.user.services.noctalia.Service.Restart == "on-failure";
assert builtins.any (hasInfix "/bin/noctalia")
  standalone.systemd.user.services.noctalia.Service.ExecStart;
assert assertHm standalone;
assert assertHm standaloneArm;
assert hasInfix "/bin/nu --login" standalone.home.file.".config/ghostty/config".text;
"dendritic-config-eval=PASS"
