{ config, pkgs, ... }:
{

  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.packages = [
    pkgs.oh-my-zsh
  ];

  programs.zsh = {
    enable = true;
    shellAliases = {
      update = "nix run nix-darwin -- switch --flake ~/.config/nix-config";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "1password"
        "battery"
        "gh"
        "dotnet"
      ];
      theme = "agnoster";
    };
  };

  programs.git = {
    enable = true;
    userName = "Lisa Scheers";
    userEmail = "lisa@scheers.tech";
    extraConfig = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      init.defaultBranch = "main";

    };
  };

  programs.ssh = {
    enable = true;
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/1password"
    ];
    matchBlocks = {

    };
  };

  home.file = {
    _1password_ssh = {
      enable = true;
      text = ''
        Host *
        	IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
      target = ".ssh/1password";
    };
  };

  home.sessionVariables = {

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
