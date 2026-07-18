{ den, ... }:
{
  # Compatibility alias. The sole Darwin entity selects aarch64-darwin by
  # name, and that named-host aspect owns its complete inward-only chain.
  den.aspects.darwin-workstation.includes = [ den.aspects.workstation-role-darwin ];
}
