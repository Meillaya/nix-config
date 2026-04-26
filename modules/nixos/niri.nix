{ pkgs, zen-browser, ... }:

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
    ];
    config.common.default = [
      "gnome"
      "gtk"
    ];
  };

  environment.systemPackages = with pkgs; [
    awww
    kdePackages.polkit-kde-agent-1
    niri
    noctalia-shell
    quickshell
    xwayland-satellite
    zen-browser.packages.${pkgs.system}.default
  ];
}
