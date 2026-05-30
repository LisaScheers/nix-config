{
  appsDir,
  localConfig,
  root,
}: {
  hostKindForSystem = system:
    if system == localConfig.darwinSystem
    then "darwin"
    else if system == localConfig.nixosSystem
    then "nixos"
    else "none";

  mkWorkflowApp = {
    hostKind,
    lib,
    name,
    pkgs,
    runtimeInputs,
    system,
  }: let
    script = appsDir + "/${name}.sh";
    app = pkgs.writeShellApplication {
      name = "nix-config-${name}";
      inherit runtimeInputs;
      text = ''
        export NIX_CONFIG_SYSTEM=${lib.escapeShellArg system}
        export NIX_CONFIG_HOST_KIND=${lib.escapeShellArg hostKind}
        export NIX_CONFIG_DARWIN_HOST=${lib.escapeShellArg localConfig.darwinHost}
        export NIX_CONFIG_NIXOS_HOST=${lib.escapeShellArg localConfig.nixosHost}
        export NIX_CONFIG_GC_AGE=${lib.escapeShellArg localConfig.garbageCollectionAge}

        exec ${pkgs.bash}/bin/bash ${script} "$@"
      '';
    };
  in {
    type = "app";
    program = "${app}/bin/nix-config-${name}";
  };

  mkNixSource = lib:
    builtins.path {
      name = "nix-config-nix-source";
      path = root;
      filter = path: type: let
        baseName = baseNameOf path;
        relPath = lib.removePrefix ((toString root) + "/") (toString path);
      in
        (type == "directory" && !(lib.elem baseName [".git" ".direnv"]))
        || lib.hasSuffix ".nix" relPath;
    };

  mkFormattingCheck = {
    pkgs,
    src,
  }:
    pkgs.runCommand "nix-config-formatting-check" {
      nativeBuildInputs = [pkgs.alejandra];
      inherit src;
    } ''
      cp -r "$src" source
      chmod -R u+w source
      alejandra --check source
      touch "$out"
    '';

  mkFormatter = pkgs:
    pkgs.writeShellApplication {
      name = "alejandra-format";
      runtimeInputs = [pkgs.alejandra];
      text = ''
        has_path=0
        for arg in "$@"; do
          case "$arg" in
            -*) ;;
            *) has_path=1 ;;
          esac
        done

        if [ "$has_path" -eq 0 ]; then
          set -- "$@" .
        fi

        alejandra "$@"
      '';
    };
}
