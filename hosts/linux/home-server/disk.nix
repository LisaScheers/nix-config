{}: {
  disko = {
    devices = {
      disk = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S392NF0N512288N-part1";
        type = "disk";
        format = "gpt";
      };
      partition = {
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S392NF0N512288N-part1";
        type = "partition";
        format = "gpt";
        size = "100%";
        fsType = "ext4";
      };
    };
  };
  filesystems = {
    ext4 = {
      mountpoint = "/";
      device = "/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S392NF0N512288N-part1";
      fsType = "ext4";
    };
  };
}
