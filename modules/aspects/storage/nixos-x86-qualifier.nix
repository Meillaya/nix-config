{ den, ... }:
{
  den.aspects.nixos-x86-qualifier-storage =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.storage.profile == "none";
    {
    includes = [
      den.aspects.pending-x86-qualifier-hardware
      den.aspects.nixos-x86-qualifier-hardware-routing
    ];
    nixos.assertions = [
      {
        assertion = machine.storage.profile == "none";
        message = "nixos-x86-qualifier storage must remain disabled until enrollment";
      }
    ];
    };
}
