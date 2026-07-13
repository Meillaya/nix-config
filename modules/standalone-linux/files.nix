{ pkgs, homeDirectory }:
let
  ghosttyConfig = builtins.replaceStrings
    [ "@NU_COMMAND@" ]
    [ "${pkgs.nushell}/bin/nu --login" ]
    (builtins.readFile ./config/ghostty/config.ghostty);
in
{
  ".config/niri/config.kdl".text = builtins.readFile ../linux/config/niri/config.kdl;

  ".config/calibre/gui.json".source = ./config/calibre/gui.json;
  ".config/calibre/tweaks.json".source = ./config/calibre/tweaks.json;
  ".config/calibre/save_to_disk.py.json".source = ./config/calibre/save_to_disk.py.json;
  ".config/calibre/metadata_sources/global.json".source = ./config/calibre-metadata-sources-global.json;
  ".config/calibre/conversion/page_setup.py".source = ./config/calibre/conversion/page_setup.py;
  ".claude/.omc-config.json".source = ./config/claude/omc-config.json;
  ".claude/settings.json".source = ./config/claude/settings.json;
  ".claude/CLAUDE.md".source = ./config/claude/CLAUDE.md;
  ".config/zed/settings.json".source = ./config/zed/settings.json;
  ".config/ghostty/config" = {
    text = ghosttyConfig;
    force = true;
  };
  ".config/ghostty/config.ghostty".text = ghosttyConfig;
  ".config/fastfetch/config.jsonc".source = ../shared/config/fastfetch/config.jsonc;
  ".config/fastfetch/snoopy-mugiwara.png".source = ../shared/config/fastfetch/snoopy-mugiwara.png;

  ".config/waybar/config".source = ./config/waybar/config;
  ".config/waybar/modules.json".source = ./config/waybar/modules.json;
  ".config/waybar/style.css".source = ./config/waybar/style.css;
  ".config/waybar/waybar.sh" = {
    source = ./config/waybar/waybar.sh;
    executable = true;
  };
  ".config/waybar/scripts/power-menu.sh" = {
    source = ./config/waybar/scripts/power-menu.sh;
    executable = true;
  };
  ".config/waybar/scripts/waybar-restart.sh" = {
    source = ./config/waybar/scripts/waybar-restart.sh;
    executable = true;
  };

  ".config/mako/config".source = ./config/mako/config;

  ".omx/hud-config.json".source = ./config/omx/hud-config.json;

  ".config/wlogout/layout".source = ./config/wlogout/layout;
  ".config/wlogout/style.css".source = ./config/wlogout/style.css;
}
