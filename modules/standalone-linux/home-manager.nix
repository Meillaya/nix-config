{ config, pkgs, lib, ... }:

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
in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = user;
    homeDirectory = homeDirectory;
    packages = pkgs.callPackage ./packages.nix {};
    file = shared-files;
    stateVersion = "25.11";
  };

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  programs = shared-programs // {
    gpg.enable = true;
    home-manager.enable = true;
  };
}
