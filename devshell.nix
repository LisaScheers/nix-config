{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    inputs',
    ...
  }: {
    devShells.default = pkgs.mkShellNoCC {
      packages =
        [
          pkgs.just
          pkgs.sops
          pkgs.age
          pkgs.ssh-to-age
          pkgs.nil
          inputs'.home-manager.packages.home-manager
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          inputs'.nix-darwin.packages.darwin-rebuild
        ];

      shellHook = ''
        echo "Nix Config Development Shell"
        echo "Available commands:"
        echo "  just fmt          - Format all Nix files"
        echo "  just darwin       - Rebuild Darwin configuration"
        echo "  just nixos        - Rebuild NixOS configuration"
        echo "  just sops         - Edit secrets"
        echo "  just check        - Check flake"
      '';
    };
  };
}
