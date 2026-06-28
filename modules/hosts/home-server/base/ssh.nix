{...}: {
  localModules.nixos."home-server-base-ssh" = {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "yes";
        PermitEmptyPasswords = false;
        PermitUserEnvironment = false;
      };
    };
  };
}
