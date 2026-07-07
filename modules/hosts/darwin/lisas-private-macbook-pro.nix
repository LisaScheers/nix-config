{config, ...}: let
  flakeConfig = config;
in {
  localModules.darwin."macbook-pro" = {
    config,
    darwinHost,
    darwinHostConfig,
    flakeRevision,
    lib,
    localConfig,
    pkgs,
    ...
  }: {
    system.primaryUser = localConfig.primaryUser;
    users.users.${localConfig.primaryUser} = {
      uid = localConfig.primaryUserUid;
      shell = pkgs.zsh;
    };

    networking = {
      computerName = darwinHostConfig.computerName or darwinHost;
      hostName = darwinHostConfig.hostName or darwinHost;
      localHostName = darwinHostConfig.localHostName or darwinHost;
    };

    security.pam.services.sudo_local.touchIdAuth = true;

    system.configurationRevision = lib.mkDefault flakeRevision;
    system.stateVersion = 6;

    nixpkgs.hostPlatform = darwinHostConfig.system or localConfig.darwinSystem;

    environment.etc."zshenv".text = lib.mkForce ''
      # /etc/zshenv: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for all shells.

      # Only execute this file once per shell.
      if [ -n "''${__ETC_ZSHENV_SOURCED-}" ]; then return; fi
      __ETC_ZSHENV_SOURCED=1

      if [[ -o rcs ]]; then
        __nix_darwin_original_term="''${TERM-}"

        if [ "''${TERM-}" = alacritty ]; then
          export TERM=xterm-256color
        fi

        if [ -z "''${__NIX_DARWIN_SET_ENVIRONMENT_DONE-}" ]; then
          . ${config.system.build.setEnvironment}
        fi

        if [ "''${__nix_darwin_original_term-}" = alacritty ]; then
          export TERM=alacritty
        fi

        unset __nix_darwin_original_term

        # Tell zsh how to find installed completions.
        for p in ''${(z)NIX_PROFILES}; do
          fpath=($p/share/zsh/site-functions $p/share/zsh/$ZSH_VERSION/functions $p/share/zsh/vendor-completions $fpath)
        done

        ${config.programs.zsh.shellInit}
      fi

      # Read system-wide modifications.
      if test -f /etc/zshenv.local; then
        source /etc/zshenv.local
      fi
    '';

    system.activationScripts.postActivation.text = ''
      echo "configuring VS Code command..." >&2

      vscode_code="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
      code_link="/usr/local/bin/code"

      if [ -x "$vscode_code" ]; then
        install -d -m 0755 /usr/local/bin

        if [ -e "$code_link" ] && [ ! -L "$code_link" ]; then
          echo "warning: $code_link exists and is not a symlink; leaving it unchanged" >&2
        else
          ln -sfn "$vscode_code" "$code_link"
        fi
      else
        echo "warning: VS Code command not found at $vscode_code" >&2
      fi

      echo "configuring ${localConfig.primaryUser} login shell..." >&2

      user=${lib.escapeShellArg localConfig.primaryUser}
      zsh_shell="/run/current-system/sw/bin/zsh"
      current_shell=$(dscl . -read "/Users/$user" UserShell 2>/dev/null | sed 's/^UserShell: //')

      if [ "$current_shell" != "$zsh_shell" ]; then
        dscl . -create "/Users/$user" UserShell "$zsh_shell"
      fi
    '';

    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      age.keyFile = localConfig.sopsAgeKeyFile;
    };
  };

  localModules.darwin."lisas-private-macbook-pro" = {
    imports = [
      flakeConfig.localModules.darwin."macbook-pro"
    ];
  };

  localModules.darwin.vega = {
    imports = [
      flakeConfig.localModules.darwin."macbook-pro"
    ];
  };
}
