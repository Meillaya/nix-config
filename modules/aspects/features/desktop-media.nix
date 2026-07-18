{ den, inputs, ... }:
{
  den.aspects.desktop-media = {
    nixos =
      { lib, pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        supported = system == "x86_64-linux";
      in
      {
        imports = [ inputs.spicetify-nix.nixosModules.spicetify ];

        config = lib.mkIf supported {
          programs.spicetify.enable = true;

          environment.systemPackages = [
            inputs.helium.packages.${system}.default
          ];
        };
      };

    homeManager =
      { lib, pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        supported = system == "x86_64-linux";
      in
      {
        # Module imports are static; support is gated in config below so module
        # argument resolution cannot recurse through pkgs during import loading.
        imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

        config = lib.mkIf supported {
          # Spicetify provides the wrapped Spotify package; do not also install
          # pkgs.spotify because both packages expose the same executables.
          programs.spicetify.enable = true;

          home.packages = [
            inputs.helium.packages.${system}.default
          ];
        };
      };
  };
}
