{ den, ... }:
{
  den.aspects.nixos-laptop-storage =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.storage.profile == "none";
    {
    includes = [
      den.aspects.pending-x86-workstation-hardware
      den.aspects.nixos-laptop-hardware-routing
    ];
    nixos.assertions = [
      {
        assertion = machine.storage.profile == "none";
        message = "nixos-laptop storage must remain disabled until enrollment";
      }
    ];
    };
}
