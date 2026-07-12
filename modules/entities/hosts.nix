{ den, inputs, ... }:
let
  nixpkgsPolicy = import ../../lib/nixpkgs.nix { inherit inputs; };
in
{
  den.hosts = {
    x86_64-linux.x86_64-linux = {
      aspect = den.aspects.nixos-workstation;
      hostName = "nixos";
      users.mei = { };
    };
    aarch64-linux.aarch64-linux = {
      aspect = den.aspects.nixos-workstation;
      hostName = "nixos-aarch64";
      users.mei = { };
    };
    aarch64-darwin.aarch64-darwin = {
      aspect = den.aspects.darwin-workstation;
      users.mei = { };
    };
    x86_64-darwin.x86_64-darwin = {
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
