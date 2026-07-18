{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    checks = {
      dendritic-architecture = pkgs.runCommand "dendritic-architecture" {
        nativeBuildInputs = [ pkgs.bash pkgs.fastfetch pkgs.gnugrep pkgs.python3 ];
        DENDRITIC_DARWIN_CONFIGURATION_SYSTEMS =
          builtins.toJSON (builtins.attrNames inputs.self.darwinConfigurations);
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
        nativeBuildInputs = [ pkgs.bash pkgs.gawk pkgs.nix pkgs.python3 ];
        NIX_CONFIG = "experimental-features = nix-command flakes";
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/dendritic-apps.sh
        touch "$out"
      '';

      sync-secrets = pkgs.runCommand "sync-secrets" {
        nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.gnugrep ];
        SYNC_SECRETS_APP_PROGRAM_X86_64_LINUX =
          builtins.unsafeDiscardStringContext inputs.self.apps.x86_64-linux.sync-secrets.program;
        SYNC_SECRETS_APP_PROGRAM_AARCH64_LINUX =
          builtins.unsafeDiscardStringContext inputs.self.apps.aarch64-linux.sync-secrets.program;
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/sync-secrets.sh
        touch "$out"
      '';

      package-policy = pkgs.runCommand "package-policy" {
        nativeBuildInputs = [ pkgs.bash pkgs.gnugrep pkgs.nix pkgs.python3 ];
        DENDRITIC_POLICY_REPO_ROOT = "${inputs.self}";
        DENDRITIC_NIXPKGS_FLAKE = "${inputs.nixpkgs}";
        DENDRITIC_EMACS_OVERLAY_FLAKE = "${inputs.emacs-overlay}";
        src = inputs.self;
      } ''
        cp -R "$src" source
        chmod -R u+w source
        bash source/tests/package-policy.sh
        touch "$out"
      '';

      dendritic-config-eval =
        assert (import ../../tests/dendritic-config-eval.nix { flake = inputs.self; })
          == "dendritic-config-eval=PASS";
        pkgs.runCommand "dendritic-config-eval" { } ''
          touch "$out"
        '';

      dendritic-shells = pkgs.runCommand "dendritic-shells" {
        nativeBuildInputs = [ pkgs.bash ];
        DENDRITIC_NU_BIN = "${pkgs.nushell}/bin/nu";
        DENDRITIC_BASH_BIN = "${pkgs.bashInteractive}/bin/bash";
        DENDRITIC_ZSH_BIN = "${pkgs.zsh}/bin/zsh";
        DENDRITIC_FISH_BIN = "${pkgs.fish}/bin/fish";
        src = inputs.self;
      } ''
        bash "$src/tests/dendritic-shells.sh"
        touch "$out"
      '';
    };
  };
}
