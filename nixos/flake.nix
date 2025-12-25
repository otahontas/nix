{
  description = "NixOS configuration for Tart VM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixos-generators,
      ...
    }:
    let
      linuxSystem = "aarch64-linux";
    in
    {
      # NixOS image for Tart
      packages.${linuxSystem}.nixos-image = nixos-generators.nixosGenerate {
        system = linuxSystem;
        format = "raw-efi";
        modules = [ ./tart.nix ];
      };

      # Convenience alias
      packages.${linuxSystem}.default = self.packages.${linuxSystem}.nixos-image;
    };
}
