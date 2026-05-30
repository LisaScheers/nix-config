{
  config,
  withSystem,
  ...
}: {
  nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system (
    {pkgs, ...}: pkgs
  );
}
