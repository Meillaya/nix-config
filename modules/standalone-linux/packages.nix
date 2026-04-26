{ pkgs, inputs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
  setup-ddc-brightness = writeShellScriptBin "setup-ddc-brightness" ''
    set -euo pipefail

    tmpdir="$(${coreutils}/bin/mktemp -d)"
    cleanup() {
      ${coreutils}/bin/rm -rf "$tmpdir"
    }
    trap cleanup EXIT

    modules_conf="$tmpdir/i2c-dev.conf"
    udev_rules="$tmpdir/70-i2c.rules"

    ${coreutils}/bin/printf 'i2c-dev\n' > "$modules_conf"
    ${coreutils}/bin/printf 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660", TAG+="uaccess"\n' > "$udev_rules"

    echo "Installing DDC/CI brightness support for external monitors..."
    ${sudo}/bin/sudo ${coreutils}/bin/install -Dm0644 "$modules_conf" /etc/modules-load.d/i2c-dev.conf
    ${sudo}/bin/sudo ${shadow}/bin/groupadd -f i2c
    ${sudo}/bin/sudo ${coreutils}/bin/install -Dm0644 "$udev_rules" /etc/udev/rules.d/70-i2c.rules
    ${sudo}/bin/sudo ${kmod}/bin/modprobe i2c-dev
    ${sudo}/bin/sudo ${systemd}/bin/udevadm control --reload-rules
    ${sudo}/bin/sudo ${systemd}/bin/udevadm trigger

    if ! ${coreutils}/bin/id -nG "$USER" | ${gnugrep}/bin/grep -qw i2c; then
      ${sudo}/bin/sudo ${shadow}/bin/usermod -aG i2c "$USER"
      echo "Added $USER to the i2c group. Log out and back in before relying on group permissions."
    fi

    echo
    echo "Current DDC detection:"
    ${ddcutil}/bin/ddcutil detect || true
  '';
in
shared-packages ++ [
  awww
  brightnessctl
  brave
  calibre
  cliphist
  ddcutil
  fontconfig
  fuzzel
  gimp
  ghostty
  helium
  kdePackages.polkit-kde-agent-1
  keepassxc
  libnotify
  mako
  nautilus
  niri
  obsidian
  ollama
  pavucontrol
  playerctl
  qbittorrent
  quickshell
  swaybg
  tailscale
  waybar
  wl-clipboard
  wlogout
  wofi
  xwayland-satellite
  xdg-utils
  zathura
  opencode
  setup-ddc-brightness
  inputs.zen-browser.packages.${pkgs.system}.default
]
