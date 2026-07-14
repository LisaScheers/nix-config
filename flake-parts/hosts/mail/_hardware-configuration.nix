{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ata_piix"
    "sd_mod"
    "sr_mod"
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
