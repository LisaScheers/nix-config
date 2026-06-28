{lib, ...}: {
  options.localModules = {
    darwin = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
    };

    home = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
    };

    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
    };
  };
}
