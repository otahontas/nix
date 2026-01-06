{
  description = "otahontas home-manager config";

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
    inputs@{
      catppuccin,
      home-manager,
      nixpkgs,
      ...
    }:
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
        extraSpecialArgs = {
          inherit inputs username homeDirectory;
        };
        modules = [
          catppuccin.homeModules.catppuccin
          (
            { lib, ... }:
            let
              homeConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
                lib.filesystem.listFilesRecursive ./configs/home
              );
            in
            {
              imports = homeConfigFiles;

              home.username = username;
              home.homeDirectory = homeDirectory;
              home.stateVersion = "25.05";
              xdg.enable = true;
            }
          )
        ];
      };
    };
}
