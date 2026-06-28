{...}: {
  localModules.nixos."home-server-base-packages" = {
    lib,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs;
      map lib.lowPrio [
        git
        nano
      ];
  };
}
