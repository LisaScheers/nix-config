{
  config,
  flakeRevision,
  lib,
  localConfig,
  ...
}: {
  system.primaryUser = localConfig.primaryUser;
  users.users.${localConfig.primaryUser}.uid = localConfig.primaryUserUid;

  security.pam.services.sudo_local.touchIdAuth = true;

  system.configurationRevision = lib.mkDefault flakeRevision;
  system.stateVersion = 6;

  nixpkgs.hostPlatform = localConfig.darwinSystem;

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
  '';

  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.keyFile = localConfig.sopsAgeKeyFile;
  };
}
