let
  flake = builtins.getFlake ("path:" + toString ../.);
  nixos = flake.nixosConfigurations."x86_64-linux".config;
  darwin = flake.darwinConfigurations."aarch64-darwin".config;
  standalone = flake.homeConfigurations."standalone-linux".config;
  shellName = shell: shell.pname or shell.name or (builtins.baseNameOf (toString shell));
  expectedLinuxApps = [
    "apply" "build-switch" "check-keys" "clean" "copy-keys" "create-keys"
    "home-news" "home-switch" "install" "install-with-secrets" "search-pkgs"
    "sync-secrets" "update"
  ];
  expectedDarwinApps = [
    "apply" "build" "build-switch" "check-keys" "clean" "copy-keys"
    "create-keys" "rollback" "search-pkgs" "update"
  ];
  hasShell = name: shells: builtins.any (shell: shellName shell == name) shells;
  hasInfix = flake.inputs.nixpkgs.lib.hasInfix;
  assertHm = hm:
    assert hm.programs.nushell.enable;
    assert hm.programs.nushell.settings.show_hints;
    assert hm.programs.nushell.settings.history.file_format == "sqlite";
    assert hm.programs.nushell.settings.history.sync_on_enter;
    assert hm.programs.nushell.settings.completions.algorithm == "fuzzy";
    assert hm.programs.nushell.settings.color_config.hints == "light_cyan";
    assert hasInfix "fastfetch" hm.programs.nushell.extraConfig;
    assert hm.programs.bash.enable;
    assert hm.programs.zsh.enable;
    assert hm.programs.fish.enable;
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
assert nixos.users.users.mei.hashedPasswordFile == "/var/lib/nixos-bootstrap/mei-password.hash";
assert shellName nixos.users.users.mei.shell == "nushell";
assert hasShell "nushell" nixos.environment.shells;
assert hasShell "bash" nixos.environment.shells;
assert hasShell "zsh" nixos.environment.shells;
assert hasShell "fish" nixos.environment.shells;
assert assertHm nixos.home-manager.users.mei;
assert hasInfix "/bin/nu --login"
  nixos.home-manager.users.mei.home.file."/home/mei/.local/share/konsole/Garuda.profile".text;
assert darwin.system.stateVersion == 5;
assert darwin.system.primaryUser == "mei";
assert shellName darwin.users.users.mei.shell == "nushell";
assert hasShell "nu" darwin.environment.shells;
assert hasShell "bash" darwin.environment.shells;
assert hasShell "zsh" darwin.environment.shells;
assert hasShell "fish" darwin.environment.shells;
assert assertHm darwin.home-manager.users.mei;
assert standalone.home.username == "mei";
assert standalone.home.homeDirectory == "/home/mei";
assert standalone.home.stateVersion == "25.11";
assert assertHm standalone;
assert hasInfix "/bin/nu --login" standalone.home.file.".config/ghostty/config".text;
assert hasInfix "/bin/nu --login" standalone.home.file.".config/kitty/kitty.conf".text;
"dendritic-config-eval=PASS"
