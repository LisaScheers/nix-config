{
  config,
  pkgs,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "lisa";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.11";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    git
    htop
    tree
    starship
    pnpm
    nodejs_24
  ];

  xdg = {
    enable = true;
  };

  home.file = {
    ".ssh/SSH Key DevOps.pub".source = ./ssh/public-keys/ssh-key-devops.pub;
    ".ssh/dev.pub".source = ./ssh/public-keys/dev.pub;
    ".ssh/devops-odisee.pub".source = ./ssh/public-keys/devops-odisee.pub;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml); # todo: configure in nix syntax
  };

  # direnv - automatically load/unload environment variables based on .envrc files
  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # Explicitly enable zsh integration
    enableBashIntegration = true; # Enable bash integration as well
    nix-direnv.enable = true; # Faster direnv with Nix support
    config = {
      # Global configuration for direnv
      global = {
        # Hide direnv output by default (can be verbose)
        hide_env_diff = true;
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = ["~/.orbstack/ssh/config"];
    settings = {
      "aws-moq" = {
        HostName = "13.51.254.84";
        User = "ec2-user";
        IdentityFile = "~/.ssh/moq-aws";
        IdentitiesOnly = true;
      };

      "devops-odisee" = {
        HostName = "ssh.dev.azure.com";
        User = "git";
        IdentityFile = "~/.ssh/devops-odisee.pub";
        IdentitiesOnly = true;
      };

      "mail" = {
        HostName = "dns.scheers.tech";
        User = "lisa";
        Port = 2222;
        PreferredAuthentications = "password";
      };

      "mail-hetzner" = {
        HostName = "188.245.70.181";
        User = "root";
        Port = 22;
        IdentityFile = "~/.ssh/hetzner";
        IdentitiesOnly = true;
      };

      "mail-hetzner-ts" = {
        HostName = "100.121.88.128";
        User = "root";
        Port = 22;
        IdentityFile = "~/.ssh/hetzner";
        IdentitiesOnly = true;
      };

      "mc" = {
        HostName = "91.99.142.26";
        User = "root";
        IdentityFile = "~/.ssh/hetzner-mc";
        IdentitiesOnly = true;
      };

      "dev" = {
        HostName = "89.169.108.115";
        User = "cloud";
        IdentityFile = "~/.ssh/dev.pub";
        IdentitiesOnly = true;
      };

      "router" = {
        HostName = "192.168.1.1";
        User = "root";
        PreferredAuthentications = "keyboard-interactive";
      };

      "matrix" = {
        HostName = "matrix.bylisa.dev";
        User = "lisa";
        IdentityFile = "~/.ssh/hetzner-mc";
        IdentitiesOnly = true;
      };

      "*" = {
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
    };
  };

  programs._1password-shell-plugins = {
    enable = true;
    plugins = with pkgs; [gh awscli2 cachix];
    package = pkgs._1password-cli;
  };

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Lisa Scheers";
        email = "lisa@scheers.tech";
        signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHM77QyWYhDIEUzvyv57MoXgtO8zokNcIM0q442WUX61";
      };
      init = {
        defaultBranch = "main";
      };
      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      commit = {
        gpgsign = true;
      };
    };
  };

  # Shell configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      codex = "nix run github:sadjow/codex-cli-nix -- --yolo";
    };
    # new config dir
  };

  # env variables
  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    SOPS_AGE_KEY_CMD = "op item get ympq3ilboihqml7agfdb5ejxay --fields notesPlain --format=json | jq .value -r";
    SSH_AUTH_SOCK = "~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # Zsh configuration (common on macOS)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      codex = "nix run github:sadjow/codex-cli-nix -- --yolo";
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "docker" "kubectl"];
      theme = "robbyrussell";
    };
    # new config dir
    dotDir = "${config.xdg.configHome}/zsh";
  };

  # nushell configuration
  programs.nushell = {
    enable = true;
    plugins = [
      pkgs.nushellPlugins.polars
      pkgs.nushellPlugins.formats
      pkgs.nushellPlugins.gstat
      pkgs.nushellPlugins.query
      #pkgs.nushellPlugins.inc
      #pkgs.nushellPlugins.highlight
    ];
    settings = {
      show_banner = false;
    };
    extraEnv = "alias codex = nix run github:sadjow/codex-cli-nix -- --yolo";
  };
}
