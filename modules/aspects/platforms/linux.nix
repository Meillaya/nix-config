{ den, ... }:
{
  den.aspects.linux-platform.includes = [
    den.aspects.shared-policy
    den.aspects.nixos-base
    den.aspects.secrets
    den.aspects.desktop-media
  ];
}
