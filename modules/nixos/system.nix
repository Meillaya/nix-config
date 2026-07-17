{ pkgs, ... }:

{
  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ "uinput" "i2c-dev" ];
    # Intentionally use the Nixpkgs default kernel. Hardware enrollment may
    # select a different, separately reviewed profile later.
    kernelPackages = pkgs.linuxPackages;
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      allowed-users = [ "@users" ];
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  networking.networkmanager.enable = true;

  programs = {
    dconf.enable = true;
    gnupg.agent.enable = true;
    wireshark.enable = true;
    zsh.enable = true;
  };

  services = {
    displayManager.defaultSession = "niri";
    xserver = {
      enable = true;
      displayManager.lightdm = {
        enable = true;
        greeters.slick.enable = true;
        background = ./config/login-wallpaper.png;
      };
    };
    libinput.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };
    fstrim.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  hardware = {
    bluetooth.enable = true;
    graphics.enable = true;
    i2c.enable = true;
    ledger.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      logDriver = "json-file";
    };
    libvirtd.enable = true;
  };

  systemd.user.services.emacs.serviceConfig.TimeoutStartSec = "7min";

  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    feather-font
    jetbrains-mono
    nerd-fonts.fira-code
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

  environment.systemPackages =
    (import ./packages.nix { inherit pkgs; })
    ++ (with pkgs; [ ethtool inetutils iw pciutils rfkill usbutils wireless-regdb ]);

  system.stateVersion = "21.05";
}
