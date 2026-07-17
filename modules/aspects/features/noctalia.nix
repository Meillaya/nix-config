{ inputs, ... }:
let
  standaloneProfile = builtins.getEnv "NIX_CONFIG_PROFILE";
in
{
  den.aspects.noctalia.nixos = {
    imports = [ inputs.noctalia.nixosModules.default ];
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      recommendedServices.enable = true;
    };
  };

  den.aspects.noctalia-home.homeManager = {
    imports = [ inputs.noctalia.homeModules.default ];
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      settings = ../../standalone-linux/config/noctalia/config.toml;
    };
  };
}
