{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      PermitEmptyPasswords = false;
      PermitUserEnvironment = false;
    };
  };
}
