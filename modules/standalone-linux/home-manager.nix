{ config, pkgs, lib, inputs, secrets, ... }:

let
  user =
    let configured = builtins.getEnv "NIXOS_CONFIG_USER";
        ambient = builtins.getEnv "USER";
    in if configured != "" then configured else if ambient != "" then ambient else "mei";
  homeDirectory =
    let configured = builtins.getEnv "NIXOS_CONFIG_HOME";
        ambient = builtins.getEnv "HOME";
    in if configured != "" then configured else if ambient != "" then ambient else "/home/${user}";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared-files = import ../shared/files.nix { inherit config pkgs; };
  standalone-files = import ./files.nix { inherit pkgs homeDirectory; };
  codexConfig =
    builtins.replaceStrings
      [ "/home/mei/.local/lib/node_modules/oh-my-codex" ]
      [ "${pkgs.oh-my-codex-sidecar}/lib/node_modules/oh-my-codex" ]
      (builtins.readFile ./config/codex/config.toml);
  codexHooks =
    builtins.replaceStrings
      [ "/home/mei/.local/lib/node_modules/oh-my-codex" ]
      [ "${pkgs.oh-my-codex-sidecar}/lib/node_modules/oh-my-codex" ]
      (builtins.readFile ./config/codex/hooks.json);
  codexConfigFile = pkgs.writeText "codex-config.toml" codexConfig;
  codexHooksFile = pkgs.writeText "codex-hooks.json" codexHooks;
  codexAgentsFile = ./config/codex/AGENTS.md;
  secret-files =
    (lib.optionalAttrs (builtins.pathExists (secrets + "/kavita/appsettings.json")) {
      "Documents/Kavita/config/appsettings.json".source = secrets + "/kavita/appsettings.json";
    })
    // (lib.optionalAttrs (builtins.pathExists (secrets + "/calibre/global.py.json")) {
      ".config/calibre/global.py.json".source = secrets + "/calibre/global.py.json";
    })
    // (lib.optionalAttrs (builtins.pathExists (secrets + "/calibre/gui.py.json")) {
      ".config/calibre/gui.py.json".source = secrets + "/calibre/gui.py.json";
    })
    // (lib.optionalAttrs (builtins.pathExists (secrets + "/calibre/customize.py.json")) {
      ".config/calibre/customize.py.json".source = secrets + "/calibre/customize.py.json";
    });
in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = user;
    homeDirectory = homeDirectory;
    packages = import ./packages.nix { inherit pkgs inputs; };
    file = shared-files // standalone-files // secret-files;
    sessionVariables = {
      BROWSER = "firefox";
      TERM = "alacritty";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      GTK_THEME = "adw-gtk3-dark";
    };
    sessionPath = [
      "${homeDirectory}/.local/bin"
      "${homeDirectory}/.ghcup/bin"
      "${homeDirectory}/.cabal/bin"
      "${homeDirectory}/.spicetify"
    ];
    stateVersion = "25.11";
  };

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  home.activation.installWritableCodexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target="${homeDirectory}/.codex/config.toml"

    $DRY_RUN_CMD mkdir -p "$(dirname "$target")"

    if [ ! -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ]; then
        $DRY_RUN_CMD rm "$target"
      fi

      $DRY_RUN_CMD install -m 0600 ${codexConfigFile} "$target"
    fi
  '';

  home.activation.installWritableCodexAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target="${homeDirectory}/.codex/AGENTS.md"

    $DRY_RUN_CMD mkdir -p "$(dirname "$target")"

    if [ ! -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ]; then
        $DRY_RUN_CMD rm "$target"
      fi

      $DRY_RUN_CMD install -m 0644 ${codexAgentsFile} "$target"
    fi
  '';

  home.activation.installWritableCodexHooks = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target="${homeDirectory}/.codex/hooks.json"

    $DRY_RUN_CMD mkdir -p "$(dirname "$target")"

    if [ ! -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ]; then
        $DRY_RUN_CMD rm "$target"
      fi

      $DRY_RUN_CMD install -m 0644 ${codexHooksFile} "$target"
    fi
  '';

  programs = shared-programs // {
    gpg.enable = true;
    home-manager.enable = true;
  };
}
