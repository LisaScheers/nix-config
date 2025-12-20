{
  lib,
  pkgs,
  ...
}: {
  # home server nixos configuration
  imports = [
    ./modules/home-assistent.nix
  ];
  environment.systemPackages = with pkgs;
    map lib.lowPrio [
      git
      nano
    ];

  #boot
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };

  #ssh
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PermitEmptyPasswords = false;
      PermitUserEnvironment = false;
    };
  };

  #users
  users.users.lisa = {
    isNormalUser = true;
    description = "Lisa Scheers";
    extraGroups = ["wheel"];
    #ssh public key

    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiE8HwWZDx2pK1p69w7rWQ2Y1RcmNj0/kF1yU1y9a3L"
    ];
  };

  #sudo
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  #nix
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["root" "lisa"];
    };
  };

  #network
  networking.hostName = "home-server";

  #firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.allowedUDPPorts = [];

  #time
  time.timeZone = "Europe/Brussels";

  #system
  system.stateVersion = "25.11";
}
