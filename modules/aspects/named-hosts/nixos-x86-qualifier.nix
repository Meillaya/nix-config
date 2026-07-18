{ den, ... }:
{
  den.aspects.nixos-x86-qualifier =
    { host, ... }:
    let
      machine = host.machine;
    in
    assert machine.target == "nixosConfigurations.${host.name}";
    assert machine.system == host.system;
    assert machine.role == "qualifier";
    {
    includes = [
      den.aspects.nixos-x86-qualifier-storage
      den.aspects.nixos-x86-qualifier-device-capability-routing
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
