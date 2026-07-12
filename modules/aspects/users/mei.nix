{ den, ... }:
{
  den.aspects.mei = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
    ];

    nixos = { pkgs, ... }: {
      environment.shells = with pkgs; [ nushell bashInteractive zsh fish ];
      users.users.mei.shell = pkgs.nushell;
    };

    darwin = { pkgs, ... }: {
      environment.shells = with pkgs; [ nushell bashInteractive zsh fish ];
      users.users.mei.shell = pkgs.nushell;
    };

    homeManager = { config, pkgs, lib, ... }: {
      gtk.gtk4.theme = config.gtk.theme;
      home.file = import ../../shared/files.nix { inherit config pkgs lib; };
      programs = (import ../../shared/home-manager.nix { inherit config pkgs lib; }) // {
        nushell = {
          enable = true;
          settings = {
            show_banner = false;
            show_hints = true;
            history = {
              file_format = "sqlite";
              max_size = 100000;
              sync_on_enter = true;
              isolation = false;
            };
            completions.algorithm = "fuzzy";
            color_config.hints = "light_cyan";
          };
          extraConfig = ''
            if $nu.is-interactive and (($env.TERM? | default "") != "dumb") {
              fastfetch --config ($env.HOME | path join ".config/fastfetch/config.jsonc")
              print ""
            }
          '';
          shellAliases = {
            pn = "pnpm";
            px = "pnpx";
            diff = "difft";
          };
        };
      };
    };
  };
}
