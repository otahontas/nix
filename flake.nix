{
  description = "otahontas nix-darwin config";

  inputs = {
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      ...
    }:
    let
      username = "otahontas";
      homeDirectory = "/Users/${username}";
    in
    {
      # nix-darwin configuration (system-level only, requires sudo)
      # For user-level configuration, use home-manager/flake.nix separately
      darwinConfigurations."otabook-work" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs self username homeDirectory;
        };
        modules = [
          ./darwin-configuration.nix
        ];
      };
    };
}
