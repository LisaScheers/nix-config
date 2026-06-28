{
  flake-file.inputs = {
    nixpkgs-authentik.url = "github:LisaScheers/nixpkgs/5105c5e9cf1a92c4888ede41a2e8deb733282feb";

    stock-keeper = {
      url = "github:LisaScheers/stock-keeper/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shop-empty-track = {
      url = "github:LisaScheers/shop-empty-track/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
