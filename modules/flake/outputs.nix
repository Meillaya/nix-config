{ ... }:
{
  # Evaluation inventory, not a claim that every target is enrolled for
  # production release or activation.
  flake.configurationEvaluationPaths = [
    "darwinConfigurations.aarch64-darwin"
    "homeConfigurations.standalone-linux"
    "homeConfigurations.standalone-linux-aarch64"
    "nixosConfigurations.aarch64-linux"
    "nixosConfigurations.nixos-x86-qualifier"
    "nixosConfigurations.x86_64-linux"
  ];
}
