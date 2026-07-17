{ config, lib, pkgs, ... }:

let
  user = config.home.username;
  managedFiles = import ./files.nix { inherit user; };
  obsoleteSessionPath = path:
    builtins.any (fragment: lib.hasInfix fragment path) [
      "/bspwm/"
      "/dunst/"
      "/polybar/"
      "/sxhkd/"
    ];
in
{
  imports = [ ../linux/home-manager.nix ];

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = [ ];
    file = lib.filterAttrs (path: _value: !obsoleteSessionPath path) managedFiles;
    stateVersion = "21.05";
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adw-gtk3;
    };
  };

  programs.gpg.enable = true;
}
