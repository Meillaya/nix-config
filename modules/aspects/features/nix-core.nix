{ inputs, ... }:
let
  policy = import ../../../lib/nixpkgs.nix { inherit inputs; };
  module = { nixpkgs = { inherit (policy) config overlays; }; };
in {
  den.aspects.nix-core = {
    nixos = module;
    darwin = module;
  };
}
