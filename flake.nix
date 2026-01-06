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
      ...
    }:
    let
      username = "otahontas";
      homeDirectory = "/Users/${username}";
    in
    {
      # Standalone home-manager configuration
      # Can be used independently of nix-darwin with: home-manager switch --flake .#otahontas
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-darwin";
          overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "claude-code"
            ];
        };
        extraSpecialArgs = {
          inherit inputs username homeDirectory;
        };
        modules = [
          catppuccin.homeModules.catppuccin
          ./home-configuration.nix
        ];
      };

      # nix-darwin configuration with integrated home-manager
      darwinConfigurations."otabook-work" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs self username homeDirectory;
        };
        modules = [
          # System-level configuration (nix-darwin)
          ./darwin-configuration.nix

          # User-level configuration (home-manager)
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit inputs username homeDirectory;
              };
              sharedModules = [ catppuccin.homeModules.catppuccin ];
              users.${username} = import ./home-configuration.nix;
            };
          }
        ];
      };
    };
}
