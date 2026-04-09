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
      ];
      config = {
        allowUnfree = true;
      };
    };
  };
}
