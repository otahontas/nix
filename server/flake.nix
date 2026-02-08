{
  description = "otapi - NixOS home server on Raspberry Pi 4";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      deploy-rs,
      ...
    }:
    let
      system = "aarch64-linux";
      hostname = "otapi";
      username = "otahontas";

      sshKeys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOyMapMZxX+mQ6hVk/uXhpkvRc4lGg5eVltxia8HP7NDIA0Xgn+6DVIVKiS6khcFF2p+3zCiKnwTpr0nloTfZmw= cardno:36_048_366"
      ];
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit username sshKeys;
        };
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./hardware-configuration.nix
          ./configuration.nix
          ./configs/tailscale
          ./configs/soft-serve
          ./configs/home-assistant
        ];
      };

      deploy.nodes.${hostname} = {
        inherit hostname;
        profiles.system = {
          user = "root";
          sshUser = username;
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
        };
      };

      checks = builtins.mapAttrs (_: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
