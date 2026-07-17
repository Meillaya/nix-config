{ den, ... }:

let
  hosts = import ../../../config/hosts.nix;
  mkProfile = host: {
    imports = [ ../../nixos/host-profile.nix ];
    nixConfig.host = host;
  };
in
{
  den.aspects = {
    nixos-laptop-profile.nixos = mkProfile hosts.nixos-laptop;
    nixos-x86-qualifier-profile.nixos = mkProfile hosts.nixos-x86-qualifier;
    aarch64-linux-profile.nixos = mkProfile hosts.aarch64-linux;
  };
}
