{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = ["/dev/disk/by-id/nvme-Samsung_SSD_980_500GB_S392NF0N512288N"];
  };
}
