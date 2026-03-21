{inputs, ...}: {
  perSystem = {
    system,
    inputs',
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          codex = inputs'.codex-cli-nix.packages.default;
        })
      ];
      config = {
        allowUnfree = true;
      };
    };
  };
}
