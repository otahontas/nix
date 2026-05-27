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
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      pi-catppuccin,
      kanttiinit-cli,
      brew-nix,
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
      pi-web-access = pkgs.callPackage ./packages/pi-web-access.nix { };
      pi-subagents = pkgs.callPackage ./packages/pi-subagents.nix { };
      pi-ralph-loop = pkgs.callPackage ./packages/pi-ralph-loop.nix { };
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit
            kanttiinit-cli
            system
            pi-mcp-adapter
            pi-web-access
            pi-subagents
            pi-ralph-loop
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
                flavor = "latte";
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
