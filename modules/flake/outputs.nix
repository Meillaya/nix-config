{ inputs, ... }:
let
  policy = import ../../lib/nixpkgs.nix { inherit inputs; };
in
{
  flake.overlays.default = inputs.nixpkgs.lib.composeManyExtensions policy.overlays;
}
