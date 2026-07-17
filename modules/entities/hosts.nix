{ den, inputs, ... }:
let
  nixpkgsPolicy = import ../../lib/nixpkgs.nix { inherit inputs; };
  hosts = import ../../config/hosts.nix;
in
{
  den.hosts = {
    x86_64-linux.x86_64-linux = {
      aspect = den.aspects.nixos-laptop;
      hostName = hosts.nixos-laptop.hostName;
      users.mei = { };
    };
    x86_64-linux.nixos-x86-qualifier = {
      aspect = den.aspects.nixos-x86-qualifier;
      hostName = hosts.nixos-x86-qualifier.hostName;
      users.mei = { };
    };
    aarch64-linux.aarch64-linux = {
      aspect = den.aspects.nixos-aarch64-evaluation;
      hostName = hosts.aarch64-linux.hostName;
      users.mei = { };
    };
    aarch64-darwin.aarch64-darwin = {
      aspect = den.aspects.darwin-workstation;
      users.mei = { };
    };
  };

  den.homes = {
    x86_64-linux.standalone-linux = {
      aspect = den.aspects.standalone-linux;
      pkgs = nixpkgsPolicy.mkPkgs "x86_64-linux";
      userName = "mei";
    };
    aarch64-linux.standalone-linux-aarch64 = {
      aspect = den.aspects.standalone-linux;
      pkgs = nixpkgsPolicy.mkPkgs "aarch64-linux";
      userName = "mei";
    };
  };
}
