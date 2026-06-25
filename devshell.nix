{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    inputs',
    ...
  }: let
    nomNixWrappers = pkgs.symlinkJoin {
      name = "nom-nix-wrappers";
      paths = [
        (pkgs.writeShellApplication {
          name = "nix";
          text = ''
            if [ "$#" -eq 0 ]; then
              exec ${pkgs.nix}/bin/nix
            fi

            case "$1" in
              build|shell|develop)
                exec ${pkgs.nix-output-monitor}/bin/nom "$@"
                ;;
              *)
                exec ${pkgs.nix}/bin/nix "$@"
                ;;
            esac
          '';
        })
        (pkgs.writeShellApplication {
          name = "nix-build";
          text = ''
            exec ${pkgs.nix-output-monitor}/bin/nom-build "$@"
          '';
        })
        (pkgs.writeShellApplication {
          name = "nix-shell";
          text = ''
            exec ${pkgs.nix-output-monitor}/bin/nom-shell "$@"
          '';
        })
      ];
    };
  in {
    devShells.default = pkgs.mkShellNoCC {
      packages =
        [
          nomNixWrappers
          pkgs.nix-output-monitor
          pkgs.just
          pkgs.sops
          pkgs.age
          pkgs.ssh-to-age
          pkgs.nil
          pkgs.nixos-anywhere
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
        echo "  just nixos-install - Install NixOS with nixos-anywhere"
        echo "  just sops         - Edit secrets"
        echo "  just check        - Check flake"
      '';
    };
  };
}
