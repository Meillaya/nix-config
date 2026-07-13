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

    darwin = { pkgs, lib, ... }: {
      environment.shells = with pkgs; [ nushell bashInteractive zsh fish ];
      users.users.mei.shell = pkgs.nushell;

      # The primary admin is intentionally not a nix-darwin managed user, so
      # users.users.mei.shell alone does not update its Directory Service
      # record. Reconcile only the login shell without taking ownership of the
      # existing account's UID, groups, or lifecycle.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        desired_shell=/run/current-system/sw/bin/nu
        if [[ ! -x "$systemConfig/sw/bin/nu" ]]; then
          printf >&2 'error: configured Nushell is not executable: %s\n' "$systemConfig/sw/bin/nu"
          exit 1
        fi

        current_shell=$(/usr/bin/dscl . -read /Users/mei UserShell)
        current_shell="''${current_shell#UserShell: }"
        if [[ "$current_shell" != "$desired_shell" ]]; then
          /usr/bin/dscl . -create /Users/mei UserShell "$desired_shell"
        fi
      '';
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
          extraEnv = ''
            $env.PATH = ([
              ($env.HOME | path join ".nix-profile/bin")
              "/run/current-system/sw/bin"
              "/nix/var/nix/profiles/default/bin"
            ] | append $env.PATH | uniq)
          '';
          extraConfig = ''
            if $nu.is-interactive and (($env.TERM? | default "") != "dumb") and (which fastfetch | is-not-empty) {
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
