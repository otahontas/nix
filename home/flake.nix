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
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    nix-audio-casks = {
      url = "github:otahontas/nix-audio-casks";
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
      brew-nix,
      nix-audio-casks,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "otahontas";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          brew-nix.overlays.default
          # https://github.com/NixOS/nixpkgs/pull/485980
          (_: prev: {
            dbus = prev.dbus.overrideAttrs (old: {
              mesonFlags = old.mesonFlags or [ ] ++ [
                (prev.lib.mesonOption "dbus_session_bus_listen_address" "unix:tmpdir=/tmp")
              ];
            });
          })

        ];
      };
      pi-mcp-adapter = pkgs.callPackage ./packages/pi-mcp-adapter.nix { };
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit
            kanttiinit-cli
            nix-audio-casks
            system
            pi-mcp-adapter
            ;
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
