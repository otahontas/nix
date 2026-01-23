{
  description = "home config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "otahontas";
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [
          catppuccin.homeModules.catppuccin
          (
            { lib, ... }:
            let
              homeConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
                lib.filesystem.listFilesRecursive ./configs
              );
            in
            {
              home = {
                inherit username;
                homeDirectory = "/Users/${username}";
                stateVersion = "25.11";
              };
              xdg.enable = true;

              # don't link gui apps through home manager
              targets.darwin.linkApps.enable = false;
              targets.darwin.copyApps.enable = false;

              # enable catppuccin globally
              catppuccin = {
                enable = true;
                flavor = "macchiato";
                accent = "blue";
              };

              # import settings
              imports = homeConfigFiles;
            }
          )
        ];
      };
    };
}
