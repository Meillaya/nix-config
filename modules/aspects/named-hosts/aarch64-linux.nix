{ den, ... }:
{
  den.aspects.aarch64-linux =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.target == "nixosConfigurations.${host.name}";
    assert machine.system == host.system;
    assert machine.role == "evaluation";
    assert machine.network == "disabled";
    assert !machine.remoteInstall;
    {
    includes = [
      den.aspects.aarch64-linux-storage
      den.aspects.aarch64-linux-device-capability-routing
    ];

    nixos =
      { lib, ... }:
      {
        networking.hostName = lib.mkForce machine.hostId;
        time.timeZone = lib.mkForce machine.location.timeZone;
        i18n.defaultLocale = lib.mkForce machine.location.locale;
        console.keyMap = lib.mkForce machine.location.keymap;
        services.xserver.xkb.layout = lib.mkForce machine.location.xkb;

        users.users.${machine.identity.name} = {
          uid = lib.mkForce machine.identity.uid;
          home = lib.mkForce machine.identity.home;
        };
        users.groups.users.gid = lib.mkForce machine.identity.gid;
      };
    };
}
