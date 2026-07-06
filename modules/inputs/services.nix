{
  flake-file.inputs = {
    stock-keeper = {
      url = "git+ssh://git@github.com/LisaScheers/stock-keeper.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shop-empty-track = {
      url = "git+ssh://git@github.com/LisaScheers/shop-empty-track.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
