{ den, inputs, ... }:
{
  den.aspects.standalone-linux = {
    includes = [
      den.aspects.mei
      den.aspects.noctalia-home
    ];
    homeManager = import ../../standalone-linux/home-manager.nix {
        inherit inputs;
        secrets = ../../../secrets;
      };
  };
}
