{ inputs, ... }:
{
  den.aspects.secrets = {
    nixos = { pkgs, ... }: {
      imports = [ inputs.agenix.nixosModules.default ../../nixos/secrets.nix ];
      environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
    darwin = { pkgs, ... }: {
      imports = [ inputs.agenix.darwinModules.default ../../darwin/secrets.nix ];
      environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
  };
}
