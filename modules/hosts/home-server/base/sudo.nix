{...}: {
  localModules.nixos."home-server-base-sudo" = {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };
}
