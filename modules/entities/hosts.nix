{ ... }:
let
  authority = import ./_machine-authority/model.nix;
  machineFor = authority.getMachine;

  laptop = machineFor "nixos-laptop";
  qualifier = machineFor "nixos-x86-qualifier";
  linuxArm = machineFor "aarch64-linux";
  darwinArm = machineFor "aarch64-darwin";
in
assert laptop.target == "nixosConfigurations.x86_64-linux";
assert qualifier.target == "nixosConfigurations.nixos-x86-qualifier";
assert linuxArm.target == "nixosConfigurations.aarch64-linux";
assert darwinArm.target == "darwinConfigurations.aarch64-darwin";
{
  den.hosts = {
    x86_64-linux = {
      x86_64-linux = {
        system = "x86_64-linux";
        hostName = laptop.hostId;
        machine = laptop;
        users.${laptop.identity.name}.identity = laptop.identity;
      };
      nixos-x86-qualifier = {
        system = "x86_64-linux";
        hostName = qualifier.hostId;
        machine = qualifier;
        users.${qualifier.identity.name}.identity = qualifier.identity;
      };
    };
    aarch64-linux = {
      aarch64-linux = {
        system = "aarch64-linux";
        hostName = linuxArm.hostId;
        machine = linuxArm;
        users.${linuxArm.identity.name}.identity = linuxArm.identity;
      };
    };
    aarch64-darwin = {
      aarch64-darwin = {
        system = "aarch64-darwin";
        hostName = darwinArm.hostId;
        machine = darwinArm;
        users.${darwinArm.identity.name}.identity = darwinArm.identity;
      };
    };
  };

  den.homes = {
    x86_64-linux.standalone-linux = {
      machine = laptop;
      userName = laptop.identity.name;
      homeDirectory = laptop.identity.home;
    };
    aarch64-linux.standalone-linux-aarch64 = {
      machine = linuxArm;
      userName = linuxArm.identity.name;
      homeDirectory = linuxArm.identity.home;
    };
  };
}
