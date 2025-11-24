{
  description = "otahontas nix-darwin + home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, neovim-nightly-overlay, ... }: {
    darwinConfigurations."otabook-work" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ({ pkgs, ... }: {
          nix.settings.experimental-features = "nix-command flakes";
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;

          users.users.otahontas.home = "/Users/otahontas";

          # Apply neovim-nightly overlay
          nixpkgs.overlays = [
            neovim-nightly-overlay.overlays.default
          ];

          # Use nix-community binary cache for prebuilt neovim
          nix.settings = {
            substituters = ["https://nix-community.cachix.org"];
            trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
          };
        })
        home-manager.darwinModules.home-manager
        ./home-manager.nix
      ];
    };
  };
}
