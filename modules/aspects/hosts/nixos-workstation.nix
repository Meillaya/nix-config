{ den, ... }:
{
  den.aspects.nixos-workstation.includes = [
    den.batteries.hostname
    den.aspects.nix-core
    den.aspects.nixos-base
    den.aspects.niri
    den.aspects.noctalia
    den.aspects.linux-desktop
  ];

  den.aspects.nixos-laptop.includes = [
    den.aspects.nixos-workstation
    den.aspects.nixos-laptop-profile
    den.aspects.storage
    den.aspects.bootstrap-password
    den.aspects.secrets
  ];

  den.aspects.nixos-x86-qualifier.includes = [
    den.aspects.nixos-workstation
    den.aspects.nixos-x86-qualifier-profile
    den.aspects.storage
    den.aspects.bootstrap-password
    den.aspects.secrets
  ];

  den.aspects.nixos-aarch64-evaluation.includes = [
    den.batteries.hostname
    den.aspects.nix-core
    den.aspects.nixos-evaluation-base
    den.aspects.aarch64-linux-profile
  ];
}
