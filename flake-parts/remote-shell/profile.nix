{
  coreutils,
  git,
  ghostty,
  ghostty-bin,
  htop,
  jq,
  lib,
  nushell,
  ripgrep,
  starship,
  starshipConfig,
  stdenv,
  tree,
  writeShellApplication,
}: let
  ghosttyTerminfo =
    if stdenv.hostPlatform.isDarwin
    then ghostty-bin.terminfo
    else ghostty.terminfo;
in
  writeShellApplication {
    name = "bylisa-shell";
    runtimeInputs = [
      coreutils
      git
      htop
      jq
      nushell
      ripgrep
      starship
      tree
    ];
    text = ''
      export BYLISA_CONFIG_TEMPLATE=${./config.nu}
      export BYLISA_ENV_TEMPLATE=${./env.nu}
      export BYLISA_GIT_CONFIG_TEMPLATE=${./gitconfig}
      export BYLISA_STARSHIP_CONFIG_TEMPLATE=${starshipConfig}
      export BYLISA_TERMINFO=${ghosttyTerminfo}/share/terminfo

      ${builtins.readFile ./launcher.sh}
    '';
    meta = {
      description = "Secret-free ephemeral Nushell profile";
      platforms = lib.platforms.unix;
      mainProgram = "bylisa-shell";
    };
  }
