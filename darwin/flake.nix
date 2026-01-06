{
  description = "nix-darwin system configuration for otahontas";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-community/nix-darwin/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    # Import home configurations from sibling directory
    home-flake.url = "path:../home";
  };

  outputs =
    {
      self,
      nix-darwin,
      home-manager,
      home-flake,
      catppuccin,
      ...
    }@inputs:
    let
      username = "otahontas";
      homeDirectory = "/Users/${username}";
    in
    {
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
                imports = [ home-flake.homeConfigurations.${username}.config ];
              };
            };
          }
        ];
      };
    };
}
