{
  description = "home config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-catppuccin = {
      url = "github:otahontas/pi-coding-agent-catppuccin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kanttiinit-cli = {
      url = "github:otahontas/kanttiinit-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      pi-catppuccin,
      kanttiinit-cli,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "otahontas";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [
          "google-chrome-144.0.7559.97"
        ];
      };
    in
    {
      # Expose manual packages for nix-update
      packages.${system} = {
        lulu = pkgs.callPackage ./packages/lulu.nix { };
        blockblock = pkgs.callPackage ./packages/blockblock.nix { };
        pearcleaner = pkgs.callPackage ./packages/pearcleaner.nix { };
        pareto-security = pkgs.callPackage ./packages/pareto-security.nix { };
        firefox-devedition-bin = pkgs.callPackage ./packages/firefox-devedition-bin.nix { };
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit kanttiinit-cli system;
        };
        modules = [
          catppuccin.homeModules.catppuccin
          pi-catppuccin.homeManagerModules.default
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

              # use copyApps for GUI apps (works with Spotlight)
              targets.darwin.linkApps.enable = false;
              targets.darwin.copyApps.enable = true;

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
