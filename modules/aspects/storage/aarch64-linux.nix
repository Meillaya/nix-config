{ den, ... }:
{
  den.aspects.aarch64-linux-storage =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.storage.profile == "none";
    {
    includes = [ den.aspects.evaluation-aarch64-hardware ];
    nixos.assertions = [
      {
        assertion = machine.storage.profile == "none";
        message = "aarch64-linux evaluation storage must remain disabled";
      }
    ];
    };
}
