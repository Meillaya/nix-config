{ config, ... }:
{
  imports = [ ./dock ];

  users.users.mei = {
    name = "mei";
    home = "/Users/mei";
    isHidden = false;
  };

  local.dock = {
    enable = true;
    username = "mei";
    entries = [
      { path = "/Applications/Safari.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Notes.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/Photo Booth.app/"; }
      { path = "/System/Applications/System Settings.app/"; }
      {
        path = "${config.users.users.mei.home}/Downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
    ];
  };
}
