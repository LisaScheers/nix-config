{localConfig, ...}: {
  imports = [
    ./modules
  ];

  home.username = localConfig.primaryUser;

  home.stateVersion = "25.11";

  xdg.enable = true;

  programs.home-manager.enable = true;
  manual.manpages.enable = false;
}
