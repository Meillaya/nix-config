{ inputs, ... }:
{
  den.aspects.secrets = { host, ... }: {
    nixos = { pkgs, ... }: {
      imports = [
        inputs.agenix.nixosModules.default
        (import ../../nixos/secrets.nix { identity = host.machine.identity; })
      ];
      environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
    darwin = { pkgs, ... }: {
      imports = [
        inputs.agenix.darwinModules.default
        (import ../../darwin/secrets.nix { identity = host.machine.identity; })
      ];
      environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
  };
}
