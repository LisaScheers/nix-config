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
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIAgMydoSwZx8riZftg5brrfbzYm8yEyCBYx1r2WmkXL";
      gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
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

  programs.nushell = {
    enable = true;
    
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
    _1password_ssh_agent_config= {
      enable = true;
      target = ".config/1Password/ssh/agent.toml";
      text= ''
        # managed by home-manager do not edit directly
        [[ssh-keys]]
        vault = "Cloudway"
        [[ssh-keys]]
        vault = "Personal"
        item="GitHub"
        [[ssh-keys]]
        vault = "Reynaers"
        item="SSH Key reynaers"
        [[ssh-keys]]
        vault = "Personal"
        item="git signature"
      '';
    };
  };

  home.sessionVariables = {

  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
