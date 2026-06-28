{...}: {
  localModules.nixos."home-server-base-boot" = {localConfig, ...}: {
    boot.initrd.systemd.enable = true;

    boot.loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      devices = [localConfig.nixosDiskDevices.system];
    };
  };
}
