{ den, ... }:
{
  den.aspects.pending-x86-qualifier-hardware =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.boot.state == "disabled";
    {
    includes = [ den.aspects.qualifier-role-linux ];
    nixos.boot.initrd.enable = false;
    };
}
