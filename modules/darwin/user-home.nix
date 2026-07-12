{ config, pkgs, lib, ... }:
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "mei";
    homeDirectory = "/Users/mei";
    packages = pkgs.callPackage ./packages.nix { };
    stateVersion = "23.11";
  };

  manual.manpages.enable = false;
}
