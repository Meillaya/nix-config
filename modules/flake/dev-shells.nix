{ inputs, ... }:
{
  perSystem = { system, ... }:
    let pkgs = inputs.nixpkgs.legacyPackages.${system};
    in {
      devShells.default = with pkgs; mkShell {
        nativeBuildInputs = [ bashInteractive git age age-plugin-yubikey ];
        shellHook = ''
          export EDITOR=vim
        '';
      };
    };
}
