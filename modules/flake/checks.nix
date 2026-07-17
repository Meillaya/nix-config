{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    checks = {
      dendritic-architecture = pkgs.runCommand "dendritic-architecture" {
        nativeBuildInputs = [ pkgs.bash pkgs.fastfetch pkgs.gnugrep ];
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/dendritic-architecture.sh
        touch "$out"
      '';

      dendritic-boundaries = pkgs.runCommand "dendritic-boundaries" {
        nativeBuildInputs = [ pkgs.bash pkgs.gnugrep ];
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/dendritic-boundaries.sh
        touch "$out"
      '';

      dendritic-apps = pkgs.runCommand "dendritic-apps" {
        nativeBuildInputs = [ pkgs.bash pkgs.gawk pkgs.python3 ];
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/dendritic-apps.sh
        touch "$out"
      '';

      machine-readiness-foundation = pkgs.runCommand "machine-readiness-foundation" {
        nativeBuildInputs = [ pkgs.bash pkgs.gnugrep pkgs.python3 ];
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/machine-readiness-foundation.sh
        touch "$out"
      '';
    };
  };
}
