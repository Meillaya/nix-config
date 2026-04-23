{
  description = "Starter Configuration with secrets for MacOS and NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    barutsrb-homebrew-tap = {
      url = "github:BarutSRB/homebrew-tap";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secrets = {
      url = "git+ssh://git@github.com/Meillaya/nix-secrets.git";
      flake = false;
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, barutsrb-homebrew-tap, home-manager, nixpkgs, disko, agenix, secrets } @inputs:
    let
      user = "mei";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
      };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      mkSearchPkgsApp = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          type = "app";
          program = "${(pkgs.writeShellScriptBin "search-pkgs" ''
            set -euo pipefail

            unstable_ref="''${NIXPKGS_SEARCH_UNSTABLE_REF:-github:nixos/nixpkgs/nixos-unstable}"
            stable_ref="''${NIXPKGS_SEARCH_STABLE_REF:-github:nixos/nixpkgs/nixos-25.11}"
            limit="''${NIXPKGS_SEARCH_LIMIT:-20}"
            query_args=()

            while [ "$#" -gt 0 ]; do
              case "$1" in
                --stable-ref)
                  stable_ref="$2"
                  shift 2
                  ;;
                --unstable-ref)
                  unstable_ref="$2"
                  shift 2
                  ;;
                --limit)
                  limit="$2"
                  shift 2
                  ;;
                --help|-h)
                  cat <<'EOF'
Usage: nix run .#search-pkgs -- [--stable-ref REF] [--unstable-ref REF] [--limit N] QUERY...

Examples:
  nix run .#search-pkgs -- ghostty
  nix run .#search-pkgs -- --limit 10 lua language server
EOF
                  exit 0
                  ;;
                *)
                  query_args+=("$1")
                  shift
                  ;;
              esac
            done

            if [ "''${#query_args[@]}" -eq 0 ]; then
              echo "search-pkgs: missing search query" >&2
              exit 2
            fi

            query="''${query_args[*]}"

            search_ref() {
              local label="$1"
              local ref="$2"
              local json

              printf '\n%s\n' "== $label =="
              printf '%s\n' "ref: $ref"

              if ! json="$(${pkgs.nix}/bin/nix --extra-experimental-features 'nix-command flakes' search --json "$ref" "$query" 2>/dev/null)"; then
                echo "search failed for $label" >&2
                return 1
              fi

              if [ "$(${pkgs.jq}/bin/jq 'length' <<<"$json")" -eq 0 ]; then
                echo "no matches"
                return 0
              fi

              ${pkgs.jq}/bin/jq -r --argjson limit "$limit" '
                to_entries
                | sort_by(.key)
                | .[:$limit]
                | .[]
                | [
                    .key,
                    (.value.version // "-"),
                    (.value.description // "-" | gsub("[\r\n\t]+"; " "))
                  ]
                | @tsv
              ' <<<"$json" | while IFS=$'\t' read -r attr version description; do
                printf '%-45s %-18s %s\n' "$attr" "$version" "$description"
              done
            }

            search_ref "unstable" "$unstable_ref"
            search_ref "stable" "$stable_ref"
          '')}/bin/search-pkgs";
        };
      mkStandaloneLinuxHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit secrets; };
        modules = [
          ./modules/standalone-linux/home-manager.nix
        ];
      };
      mkHomeSwitchApp = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          defaultTarget =
            if system == "x86_64-linux"
            then "${user}@arch-niri"
            else "${user}@linux-aarch64";
        in {
          type = "app";
          program = "${(pkgs.writeShellScriptBin "home-switch" ''
            set -euo pipefail

            target="${defaultTarget}"
            hm_args=()

            while [ "$#" -gt 0 ]; do
              case "$1" in
                --target)
                  target="$2"
                  shift 2
                  ;;
                --help|-h)
                  cat <<'EOF'
Usage: nix run .#home-switch -- [--target HOME] [home-manager args...]

Defaults:
  x86_64-linux -> mei@arch-niri
  aarch64-linux -> mei@linux-aarch64

Examples:
  nix run .#home-switch
  nix run .#home-switch -- --dry-run
  nix run .#home-switch -- --target mei@arch-niri --dry-run
EOF
                  exit 0
                  ;;
                *)
                  hm_args+=("$1")
                  shift
                  ;;
              esac
            done

            exec ${home-manager.packages.${system}.home-manager}/bin/home-manager \
              --extra-experimental-features "nix-command flakes" \
              switch \
              --flake ${self}#$target \
              ''${hm_args[@]}
          '')}/bin/home-switch";
        };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "install" = mkApp "install" system;
        "install-with-secrets" = mkApp "install-with-secrets" system;
        "home-switch" = mkHomeSwitchApp system;
        "search-pkgs" = mkSearchPkgsApp system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
        "search-pkgs" = mkSearchPkgsApp system;
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      homeConfigurations = {
        "${user}@arch-niri" = mkStandaloneLinuxHome "x86_64-linux";
        "${user}@linux-aarch64" = mkStandaloneLinuxHome "aarch64-linux";
      };

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                  "BarutSRB/homebrew-tap" = barutsrb-homebrew-tap;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
            ./hosts/darwin
          ];
        }
      );

      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = inputs;
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "before-home-manager";
              extraSpecialArgs = { inherit secrets; };
              users.${user} = import ./modules/nixos/home-manager.nix;
            };
          }
          ./hosts/nixos
        ];
     });
  };
}
