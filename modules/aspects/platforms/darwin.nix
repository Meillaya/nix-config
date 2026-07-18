{ den, ... }:
{
  den.aspects.darwin-platform.includes = [
    den.aspects.shared-policy
    den.aspects.darwin-base
    den.aspects.secrets
    den.aspects.darwin-home
  ];
}
