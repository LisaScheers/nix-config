{inputs, ...}: {
  perSystem = {
    system,
    inputs',
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (_: _: {
          codex = inputs'.codex-cli-nix.packages.default;
        })
        # Nushell's integration tests assume a full TTY/shell nesting; they fail
        # on darwin Nix builds with EPERM / wrong SHLVL (see env.rs SHLVL checks).
        (final: prev: {
          nushell =
            if prev.stdenv.hostPlatform.isDarwin
            then
              prev.nushell.overrideAttrs (_old: {
                doCheck = false;
              })
            else prev.nushell;
        })
      ];
      config = {
        allowUnfree = true;
      };
    };
  };
}
