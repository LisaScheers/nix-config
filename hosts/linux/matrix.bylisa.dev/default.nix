{
  self,
  inputs,
  ...
}: {
  flake = {
    nixosConfigurations = {
      "matrix.bylisa.dev" = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./main.nix
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          inputs.stock-keeper.nixosModules.default
          inputs.shop-empty-track.nixosModules.default
          # inputs.ip-whitelist.nixosModules.ip-whitelist
          self.nixosModules.authentik
          self.nixosModules.matrix
          self.nixosModules.forgejo-runner
          {
            matrix = {
              enable = true;
              rootDomain = "bylisa.dev";
              subDomain = "matrix";
              turnRealm = "turn.bylisa.dev";
              turnSecret = "wereturning-to-the-matrix";
              signupSecret = "wereturning-to-the-matrix";
            };
          }
        ];
      };
    };
  };
}
