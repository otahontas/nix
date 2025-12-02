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
  };

  outputs =
    inputs@{
      self,
      catppuccin,
      home-manager,
      neovim-nightly-overlay,
      nix-darwin,
      nixpkgs,
      safe-chain-nix,
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
            { pkgs, lib, ... }:
            {
              nix.settings.experimental-features = "nix-command flakes";
              system.configurationRevision = self.rev or self.dirtyRev or null;
              system.stateVersion = 6;
              system.primaryUser = username;
              users.users.${username}.home = homeDirectory;

              security.pam.services.sudo_local.touchIdAuth = true;

              system.defaults.CustomUserPreferences = {
                "com.apple.symbolichotkeys" = {
                  AppleSymbolicHotKeys = {
                    "64" = {
                      enabled = false;
                      value = {
                        parameters = [
                          65535
                          49
                          1048576
                        ];
                        type = "standard";
                      };
                    };
                  };
                };
              };

              nixpkgs.overlays = [
                inputs.neovim-nightly-overlay.overlays.default
              ];

              nix.settings = {
                substituters = [ "https://nix-community.cachix.org" ];
                trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
              };

              nixpkgs.config.allowUnfreePredicate =
                pkg:
                builtins.elem (lib.getName pkg) [
                  "claude-code"
                ];
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
                sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
                users.${username} =
                  let
                    configFiles = lib.filter (path: lib.hasSuffix ".nix" path) (
                      lib.filesystem.listFilesRecursive ./configs
                    );
                  in
                  {
                    imports = configFiles;
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
