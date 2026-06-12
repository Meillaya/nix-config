{ pkgs, zen-browser, noctalia, ... }:

{
  programs = {
    niri = {
      enable = true;
      package = pkgs.niri;
    };
    xwayland.enable = true;
  };

  security.polkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
    config.common = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [
        "kde"
        "gtk"
      ];
      "org.freedesktop.impl.portal.AppChooser" = [
        "kde"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Settings" = [
        "kde"
        "gtk"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    awww
    kdePackages.polkit-kde-agent-1
    niri
    noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    xwayland-satellite
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
