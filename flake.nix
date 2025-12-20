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
      neovim-nightly-overlay,
      nix-darwin,
      ...
    }:
    let
      username = "otahontas";
      homeDirectory = "/Users/${username}";
    in
    {
      darwinConfigurations."otabook-work" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          (
            { lib, ... }:
            let
              systemConfigFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
                lib.filesystem.listFilesRecursive ./configs/system
              );
            in
            {
              imports = systemConfigFiles;

              system.configurationRevision = self.rev or self.dirtyRev or null;
              system.stateVersion = 6;
              system.primaryUser = username;
              users.users.${username}.home = homeDirectory;
            }
          )
          home-manager.darwinModules.home-manager
          (
            { lib, ... }:
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit inputs; };
                sharedModules = [ catppuccin.homeModules.catppuccin ];
                users.${username} =
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
                  };
              };
            }
          )
        ];
      };
    };
}
