{
  den.aspects.nixos-evaluation-base.nixos = { pkgs, ... }: {
    nix = {
      package = pkgs.nix;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    environment.systemPackages = with pkgs; [ git ];

    # This output exists only to prove shared policy can evaluate on ARM. It
    # owns no boot, storage, networking, desktop, or deployment capability.
    system.stateVersion = "21.05";
  };
}
