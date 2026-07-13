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
    version = "0.19.0";
    owner = "Yeachan-Heo";
    repo = "oh-my-codex";
    sha256 = "sha256-7vSmPghxQS4NCwDKSpo8PZk77euhZTo/yLb9LAdBd7w=";
    npmDepsHash = "sha256-QqqhCdhVdluHuwnTOoBFOdE+2ys/1pILVGe+v4XHRoA=";
    updateAttr = "oh-my-codex-sidecar";
  };

  oh-my-claude-sisyphus-sidecar = mkNodeSidecar {
    pname = "oh-my-claude-sisyphus";
    version = "4.15.2";
    owner = "Yeachan-Heo";
    repo = "oh-my-claudecode";
    sha256 = "sha256-YzMJSok+B1zKeKeDiBaiJLgEIrrCkzZHs06fXIcRGOw=";
    npmDepsHash = "sha256-k+IgUj10X5XoFt8nvKe1aI/9Z5+F+Ycu9Mg7CXejkNk=";
    updateAttr = "oh-my-claude-sisyphus-sidecar";
  };
}
