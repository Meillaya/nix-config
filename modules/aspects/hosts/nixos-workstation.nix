{ den, ... }:
{
  den.aspects.nixos-workstation.includes = [
    den.aspects.nix-core
    den.aspects.nixos-base
    den.aspects.storage
    den.aspects.bootstrap-password
    den.aspects.secrets
    den.aspects.niri
    den.aspects.noctalia
    den.aspects.linux-desktop
  ];
}
