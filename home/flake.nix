{
  description = "Home Manager configuration for otahontas";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    safe-chain-nix.url = "github:LucioFranco/safe-chain-nix";
    topiary-nushell.url = "github:blindFS/topiary-nushell";
    yazi-relative-motions.flake = false;
    yazi-relative-motions.url = "github:dedukun/relative-motions.yazi";
  };

  outputs =
    {
      home-manager,
      nixpkgs,
      catppuccin,
      ...
    }@inputs:
    let
      username = "otahontas";
      homeDirectory = "/Users/${username}";
      system = "aarch64-darwin";
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "claude-code"
            ];
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./home-configuration.nix
          catppuccin.homeModules.catppuccin
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];
      };
    };
}
