{ config, lib, ... }:

let
  host = config.nixConfig.host;
  storage = host.storage;
  enrolled = host.installable && storage.state == "enrolled";
  commonMountOptions = [ "compress=zstd:3" "noatime" ];
in
{
  assertions = [
    {
      assertion = !enrolled || lib.hasPrefix "/dev/disk/by-id/" storage.diskById;
      message = "${host.hostId}: Disko refuses non-persistent disk names";
    }
  ];

  disko.devices = lib.mkIf enrolled {
    disk.main = {
      device = storage.diskById;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [ "-F" "32" ];
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = { mountpoint = "/"; mountOptions = commonMountOptions; };
                "@home" = { mountpoint = "/home"; mountOptions = commonMountOptions; };
                "@nix" = { mountpoint = "/nix"; mountOptions = commonMountOptions; };
                "@log" = { mountpoint = "/var/log"; mountOptions = commonMountOptions; };
              };
            };
          };
        };
      };
    };
  };

  services.btrfs.autoScrub = lib.mkIf enrolled {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
}
