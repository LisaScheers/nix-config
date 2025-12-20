{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      buildInputs = [
        pkgs.just
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
        inputs.nil.packages."${system}".nil
        inputs.nix-darwin.packages."${system}".darwin-rebuild
        inputs.home-manager.packages."${system}".home-manager
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
