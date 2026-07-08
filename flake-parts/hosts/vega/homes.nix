{inputs, ...}: {
  users.users.lisa.home = "/Users/lisa";

  home-manager.users.lisa.imports = [
    inputs.onepassword-shell-plugins.hmModules.default
    (../../homes + "/lisa@vega")
  ];
}
