{ den, inputs, ... }:
{
  den.aspects.standalone-linux = {
    includes = [ den.aspects.mei ];
    homeManager = import ../../standalone-linux/home-manager.nix {
        inherit inputs;
        secrets = ../../../secrets;
      };
  };
}
