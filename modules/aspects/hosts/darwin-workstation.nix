{ den, ... }:
{
  den.aspects.darwin-workstation.includes = [
    den.aspects.nix-core
    den.aspects.darwin-base
    den.aspects.darwin-dock
    den.aspects.secrets
    den.aspects.darwin-home
  ];
}
