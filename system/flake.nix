{
  description = "system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, homebrew-core, homebrew-cask, ... }:
    let
      adminUser = "otahontas-admin";
      hostname = "macbook";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          {
            system.configurationRevision = self.rev or self.dirtyRev or null;
            system.stateVersion = 6;
            system.primaryUser = adminUser;
            users.users.${adminUser}.home = "/Users/${adminUser}";

            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            environment.systemPackages = [ inputs.nixpkgs.legacyPackages.aarch64-darwin.home-manager ];

            homebrew.enable = true;
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = adminUser;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
