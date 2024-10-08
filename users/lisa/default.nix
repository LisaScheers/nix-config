{ config, pkgs, ... }:
{

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.username = "lisa";
  home.homeDirectory = "/Users/lisa";

  home.packages = [

  ];

  home.file = {

  };

  home.sessionVariables = {

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
