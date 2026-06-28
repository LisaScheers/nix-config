{...}: {
  localModules.nixos."home-server-disk" = {localConfig, ...}: let
    dataDisk = device: mountpoint: {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            inherit mountpoint;
            mountOptions = [
              "defaults"
              "noauto"
              "nofail"
              "x-systemd.device-timeout=5s"
            ];
          };
        };
      };
    };
  in {
    disko.devices.disk = {
      system = {
        device = localConfig.nixosDiskDevices.system;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            MBR = {
              priority = 0;
              size = "1M";
              type = "EF02";
            };
            ESP = {
              priority = 1;
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              priority = 2;
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      "second-life-cache-nvme" = dataDisk localConfig.nixosDiskDevices.secondLifeCacheNvme "/srv/disks/second-life-cache-nvme";
      "kingston-ssd" = dataDisk localConfig.nixosDiskDevices.kingstonSsd "/srv/disks/kingston-ssd";
      "western-digital-hdd" = dataDisk localConfig.nixosDiskDevices.westernDigitalHdd "/srv/disks/western-digital-hdd";
    };
  };
}
