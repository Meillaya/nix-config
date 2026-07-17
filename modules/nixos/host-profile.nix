{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;
  host = config.nixConfig.host;
in
{
  options.nixConfig.host = mkOption {
    description = "Closed, named machine declaration selected by its Den host aspect.";
    type = types.submodule {
      options = {
        hostId = mkOption { type = types.str; };
        hostName = mkOption { type = types.str; };
        system = mkOption { type = types.enum [ "x86_64-linux" "aarch64-linux" ]; };
        role = mkOption { type = types.enum [ "workstation" "qualifier" "evaluation" ]; };
        installable = mkOption { type = types.bool; };
        cpuVendor = mkOption { type = types.enum [ "pending" "GenuineIntel" "AuthenticAMD" ]; };
        storage = mkOption { type = types.attrs; };
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = host.system == config.nixpkgs.hostPlatform.system;
        message = "${host.hostId}: declared system does not match nixpkgs.hostPlatform.system";
      }
      {
        assertion = (!host.installable) || host.storage.state == "enrolled";
        message = "${host.hostId}: installation remains disabled until a stable disk is enrolled";
      }
      {
        assertion = host.storage.state != "enrolled"
          || lib.hasPrefix "/dev/disk/by-id/" host.storage.diskById;
        message = "${host.hostId}: enrolled storage must use /dev/disk/by-id";
      }
    ];

    networking.hostName = host.hostName;
    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";
    services.xserver.xkb = {
      layout = "us";
      options = "ctrl:nocaps";
    };

    hardware.enableRedistributableFirmware = host.role != "evaluation";
    hardware.cpu.intel.updateMicrocode = host.cpuVendor == "GenuineIntel";
    hardware.cpu.amd.updateMicrocode = host.cpuVendor == "AuthenticAMD";

    boot.loader = mkIf (host.role != "evaluation") {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
