{
  flake-file.inputs = {
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
