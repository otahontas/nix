{
  description = "home config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # TODO: remove when primary nixpkgs includes NixOS/nixpkgs#534965.
    nixpkgs-mise-fixed.url = "github:NixOS/nixpkgs/36b689324a65f495c6e01a44905457f7ca74e676";
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
    pi-nix = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    google-workspace-cli = {
      url = "github:googleworkspace/cli";
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
      nixpkgs-mise-fixed,
      home-manager,
      catppuccin,
      pi-catppuccin,
      kanttiinit-cli,
      pi-nix,
      google-workspace-cli,
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
          # TODO: remove when primary nixpkgs includes NixOS/nixpkgs#534965.
          # mise 2026.6.11 fails on Darwin because Nix sandbox strips setuid bits.
          (_: _: {
            mise = nixpkgs-mise-fixed.legacyPackages.${system}.mise;
          })
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
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit
            kanttiinit-cli
            google-workspace-cli
            system
            pi-nix
            ;
        };
        modules = [
          catppuccin.homeModules.catppuccin
          pi-catppuccin.homeManagerModules.default
          pi-nix.homeModules.default
          (
            { lib, ... }:
            let
              configDirs = lib.attrNames (
                lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./configs)
              );
              homeConfigFiles = map (name: ./configs + "/${name}/default.nix") configDirs;
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
                autoEnable = true;
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
