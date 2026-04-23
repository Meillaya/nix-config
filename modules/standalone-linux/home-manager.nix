{ config, pkgs, lib, ... }:

let
  user = "mei";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared-files = import ../shared/files.nix { inherit config pkgs; };
in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = user;
    homeDirectory = "/home/${user}";
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
