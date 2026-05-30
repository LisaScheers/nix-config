{localConfig, ...}: {
  users.users.${localConfig.primaryUser} = {
    isNormalUser = true;
    description = "Lisa Scheers";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiE8HwWZDx2pK1p69w7rWQ2Y1RcmNj0/kF1yU1y9a3L"];
  };
}
