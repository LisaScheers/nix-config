let
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
      device = "/dev/disk/by-id/nvme-eui.002538ba71b63d8a";
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
    "second-life-cache-nvme" = dataDisk "/dev/disk/by-id/nvme-eui.00080d02000707ea" "/srv/disks/second-life-cache-nvme";
    "kingston-ssd" = dataDisk "/dev/disk/by-id/ata-KINGSTON_SUV400S37240G_50026B726406FC2C" "/srv/disks/kingston-ssd";
    "western-digital-hdd" = dataDisk "/dev/disk/by-id/wwn-0x50014ee261c9005d" "/srv/disks/western-digital-hdd";
  };
}
