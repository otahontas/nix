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
      nixos-generators,
      ...
    }:
    let
      linuxSystem = "aarch64-linux";
    in
    {
      packages.${linuxSystem} =
        let
          nixos-image = nixos-generators.nixosGenerate {
            system = linuxSystem;
            format = "raw-efi";
            modules = [ ./tart.nix ];
          };
        in
        {
          inherit nixos-image;
          default = nixos-image;
        };
    };
}
