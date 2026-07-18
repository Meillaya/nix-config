{ pkgs, user, ... }:
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = user.identity.name;
    homeDirectory = user.identity.home;
    packages = pkgs.callPackage ./packages.nix { };
    stateVersion = "23.11";
  };

  manual.manpages.enable = false;
}
