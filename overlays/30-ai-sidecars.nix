self: super:
let
  mkNodeSidecar =
    {
      pname,
      version,
      owner,
      repo,
      rev,
      sha256,
      npmDepsHash,
    }:
    super.buildNpmPackage {
      inherit pname version npmDepsHash;

      src = super.fetchFromGitHub {
        inherit owner repo rev sha256;
      };

      npmBuildScript = "build";
      dontNpmPrune = true;

      meta = with super.lib; {
        homepage = "https://github.com/${owner}/${repo}";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };
in
{
  oh-my-codex-sidecar = mkNodeSidecar {
    pname = "oh-my-codex";
    version = "0.15.0";
    owner = "Yeachan-Heo";
    repo = "oh-my-codex";
    rev = "v0.15.0";
    sha256 = "sha256-jtyHUtV7N6uKNtvBoqYJU2VYJra6PpcB6hvZhl1ChRE=";
    npmDepsHash = "sha256-LqGRFLAT45mm927PoWnD+q5jroM1/cYod7rG9cFLlqU=";
  };

  oh-my-claude-sisyphus-sidecar = mkNodeSidecar {
    pname = "oh-my-claude-sisyphus";
    version = "4.13.3";
    owner = "Yeachan-Heo";
    repo = "oh-my-claudecode";
    rev = "v4.13.3";
    sha256 = "0i5kib94p1n57v5295prnaf33c508mssakxv3qylq581q9sf85bs";
    npmDepsHash = "sha256-gWXDHewhZ+53yZnqcpmQWh88UKieVsFgzAcdLIwzfdo=";
  };
}
