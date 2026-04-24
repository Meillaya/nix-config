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
  secret-files = lib.optionalAttrs (builtins.pathExists (secrets + "/kavita/appsettings.json")) {
    "Documents/Kavita/config/appsettings.json".source = secrets + "/kavita/appsettings.json";
  };
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

  programs = shared-programs // {
    gpg.enable = true;
    home-manager.enable = true;
  };
}
