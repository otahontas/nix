{
  description = "Helper for creating simple dev environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      lib.mkEnv = packageNames: {
        devShells = forAllSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            packages = map (name: pkgs.${name}) packageNames;
          in
          {
            default = pkgs.mkShell { inherit packages; };
          }
        );
      };
    };
}
