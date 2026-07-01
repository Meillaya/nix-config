{ config, pkgs, lib, home-manager, secrets, ... }:

let
  user = "mei";
  sharedFiles = import ../shared/files.nix { inherit config pkgs lib; };
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    backupCommand = toString (pkgs.writeShellScript "home-manager-backup-nonclobber" ''
      set -euo pipefail

      target="$1"
      base="$target.before-home-manager"
      backup="$base"

      if [ -e "$backup" ] || [ -L "$backup" ]; then
        stamp="$(date -u +%Y%m%dT%H%M%SZ 2>/dev/null || date +%s)"
        backup="$base.$stamp"
        counter=1

        while [ -e "$backup" ] || [ -L "$backup" ]; do
          counter=$((counter + 1))
          backup="$base.$stamp.$counter"
        done
      fi

      mv "$target" "$backup"
      echo "Backed up $target to $backup" >&2
    '');
    extraSpecialArgs = { inherit secrets; };
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          sharedFiles
        ];

        stateVersion = "23.11";
      };
      programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib secrets; };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/Applications/Safari.app/"; }
        { path = "/System/Applications/Messages.app/"; }
        { path = "/System/Applications/Notes.app/"; }
        { path = "/System/Applications/Music.app/"; }
        { path = "/System/Applications/Photos.app/"; }
        { path = "/System/Applications/Photo Booth.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
        {
          path = "${config.users.users.${user}.home}/Downloads";
          section = "others";
          options = "--sort name --view grid --display stack";
        }
      ];
    };
  };
}
