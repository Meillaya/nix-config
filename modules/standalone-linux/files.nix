{ pkgs, homeDirectory }:
{
  ".config/niri/config.kdl".text = builtins.readFile ../linux/config/niri/config.kdl;

  ".config/calibre/gui.json".source = ./config/calibre/gui.json;
  ".config/calibre/tweaks.json".source = ./config/calibre/tweaks.json;
  ".config/calibre/save_to_disk.py.json".source = ./config/calibre/save_to_disk.py.json;
  ".config/calibre/metadata_sources/global.json".source = ./config/calibre-metadata-sources-global.json;
  ".config/calibre/conversion/page_setup.py".source = ./config/calibre/conversion/page_setup.py;
  ".config/noctalia/config.toml".source = ./config/noctalia/config.toml;
  ".claude/.omc-config.json".source = ./config/claude/omc-config.json;
  ".claude/settings.json".source = ./config/claude/settings.json;
  ".claude/CLAUDE.md".source = ./config/claude/CLAUDE.md;
  ".config/zed/settings.json".source = ./config/zed/settings.json;
  ".config/ghostty/config" = {
    source = ./config/ghostty/config.ghostty;
    force = true;
  };
  ".config/ghostty/config.ghostty".source = ./config/ghostty/config.ghostty;
  ".config/kitty/kitty.conf" = {
    text = ''
    # Match Konsole's Garuda.profile + Sweet.colorscheme terminal palette.
    font_family FiraCode Nerd Font Mono
    font_size 12.0
    initial_window_width 110c
    initial_window_height 30c
    background_opacity 0.65
    copy_on_select yes
    cursor_shape underline
    cursor_blink_interval 0.5
    cursor #ff0000
    cursor_text_color #161925
    background #161925
    foreground #c3c7d1
    selection_foreground #ffffff
    selection_background #1e92ff
    color0 #697388
    color1 #ed254e
    color2 #71f79f
    color3 #f9dc5c
    color4 #7cb7ff
    color5 #c74ded
    color6 #00c1e4
    color7 #dcdfe4
    color8 #697388
    color9 #ed254e
    color10 #71f79f
    color11 #f9dc5c
    color12 #7cb7ff
    color13 #c74ded
    color14 #00c1e4
    color15 #dcdfe4
    '';
  };
  ".config/fastfetch/config.jsonc".source = ../shared/config/fastfetch/config.jsonc;
  ".config/fastfetch/snoopy-mugiwara.png".source = ./config/fastfetch/snoopy-mugiwara.png;

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
