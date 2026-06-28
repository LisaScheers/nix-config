{...}: {
  localModules.darwin."home-manager" = {
    inputs,
    lisaMacosHomeModule,
    localConfig,
    pkgs,
    ...
  }: {
    home-manager = {
      backupFileExtension = ".before-nix-home-manager";
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${localConfig.primaryUser} = lisaMacosHomeModule;
      extraSpecialArgs = {inherit inputs localConfig pkgs;};
    };
  };
}
