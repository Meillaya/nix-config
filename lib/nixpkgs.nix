{ inputs }:
let
  nixosRenderDocsCompatOverlay = self: super: {
    # nix-darwin still passes the removed --toc-depth option when building its
    # HTML manual. Translate it until nix-darwin uses --sidebar-depth itself.
    nixos-render-docs = super.symlinkJoin {
      name = "${super.nixos-render-docs.name}-toc-depth-compat";
      paths = [ super.nixos-render-docs ];
      postBuild = ''
        rm "$out/bin/nixos-render-docs"
        cat > "$out/bin/nixos-render-docs" <<'EOF'
        #!${super.runtimeShell}
        args=()
        for arg in "$@"; do
          case "$arg" in
            --toc-depth|--chunk-toc-depth|--section-toc-depth)
              args+=(--sidebar-depth)
              ;;
            --toc-depth=*|--chunk-toc-depth=*|--section-toc-depth=*)
              args+=(--sidebar-depth="''${arg#*=}")
              ;;
            *) args+=("$arg") ;;
          esac
        done
        exec ${super.nixos-render-docs}/bin/nixos-render-docs "''${args[@]}"
        EOF
        chmod +x "$out/bin/nixos-render-docs"
      '';
    };
  };
  localOverlayDirectory = ../overlays;
  localOverlayFiles = builtins.filter
    (name:
      builtins.match ".*\\.nix" name != null
      || builtins.pathExists (localOverlayDirectory + "/${name}/default.nix"))
    (builtins.attrNames (builtins.readDir localOverlayDirectory));
  overlays =
    [ nixosRenderDocsCompatOverlay ]
    ++ map (name: import (localOverlayDirectory + "/${name}")) localOverlayFiles
    ++ [ (import inputs.emacs-overlay) ];
  config = {
    allowUnfree = true;
    allowBroken = true;
    allowInsecure = false;
    permittedInsecurePackages = [ "pnpm-10.29.2" ];
    allowUnsupportedSystem = true;
  };
in
{
  inherit config overlays;
  mkPkgs = system: import inputs.nixpkgs { inherit system config overlays; };
}
