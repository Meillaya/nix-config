self: super:
let
  mkNixUpdateScript = attr: super.writeShellApplication {
    name = "update-${attr}";
    runtimeInputs = [
      super.git
      super.nix-update
    ];
    text = ''
      set -euo pipefail

      repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
      cd "$repo_root"

      nix-update \
        --flake \
        --build \
        --system ${super.stdenv.hostPlatform.system} \
        --override-filename overlays/30-ai-sidecars.nix \
        ${attr}
    '';
  };

  mkNodeSidecar =
    {
      pname,
      version,
      owner,
      repo,
      sha256,
      npmDepsHash,
      updateAttr,
    }:
    super.buildNpmPackage {
      inherit pname version npmDepsHash;

      src = super.fetchFromGitHub {
        inherit owner repo sha256;
        rev = "v${version}";
      };

      npmBuildScript = "build";
      dontNpmPrune = true;

      meta = with super.lib; {
        homepage = "https://github.com/${owner}/${repo}";
        license = licenses.mit;
        platforms = platforms.all;
      };

      passthru.updateScript = super.lib.getExe (mkNixUpdateScript updateAttr);
    };
in
{
  oh-my-codex-sidecar = mkNodeSidecar {
    pname = "oh-my-codex";
    version = "0.15.0";
    owner = "Yeachan-Heo";
    repo = "oh-my-codex";
    sha256 = "sha256-jtyHUtV7N6uKNtvBoqYJU2VYJra6PpcB6hvZhl1ChRE=";
    npmDepsHash = "sha256-LqGRFLAT45mm927PoWnD+q5jroM1/cYod7rG9cFLlqU=";
    updateAttr = "oh-my-codex-sidecar";
  };

  oh-my-claude-sisyphus-sidecar = mkNodeSidecar {
    pname = "oh-my-claude-sisyphus";
    version = "4.13.3";
    owner = "Yeachan-Heo";
    repo = "oh-my-claudecode";
    sha256 = "0i5kib94p1n57v5295prnaf33c508mssakxv3qylq581q9sf85bs";
    npmDepsHash = "sha256-gWXDHewhZ+53yZnqcpmQWh88UKieVsFgzAcdLIwzfdo=";
    updateAttr = "oh-my-claude-sisyphus-sidecar";
  };
}
