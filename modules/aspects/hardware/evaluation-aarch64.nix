{ den, ... }:
{
  den.aspects.evaluation-aarch64-hardware =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.boot.state == "disabled";
    {
    includes = [ den.aspects.evaluation-role-linux ];
    nixos.boot.initrd.enable = false;
    };
}
