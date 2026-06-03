{localConfig, ...}: {
  boot.initrd.systemd.enable = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [localConfig.nixosDiskDevices.system];
  };
}
