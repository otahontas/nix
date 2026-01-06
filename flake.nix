{
  description = "otahontas nix-darwin + home-manager config";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    safe-chain-nix.url = "github:LucioFranco/safe-chain-nix";
    topiary-nushell.url = "github:blindFS/topiary-nushell";
    yazi-relative-motions.flake = false;
    yazi-relative-motions.url = "github:dedukun/relative-motions.yazi";
  };

  outputs =
    inputs@{
      self,
      catppuccin,
      home-manager,
      nix-darwin,
      nixpkgs,
      ...
    }:
    let
      username = "otahontas";
      homeDirectory = "/Users/${username}";
    in
    {
      # Standalone home-manager configuration
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-darwin";
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

      # nix-darwin configuration with integrated home-manager
      darwinConfigurations."otabook-work" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./darwin-configuration.nix
          {
            system.configurationRevision = self.rev or self.dirtyRev or null;
            system.primaryUser = username;
            users.users.${username}.home = homeDirectory;
          }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
              sharedModules = [ catppuccin.homeModules.catppuccin ];
              users.${username} = {
                imports = [ ./home-configuration.nix ];
                home.username = username;
                home.homeDirectory = homeDirectory;
              };
            };
          }
        ];
      };
    };
}
