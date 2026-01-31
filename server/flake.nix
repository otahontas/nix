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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0zRsfVClht/LZvFfngk5O9DoDCi83gVxdxWncRn77y3YBr85g/P1oY4WiX7MSE5kB5Ud5//lD+xZu7dGOJDuZfh/cm4pXFHp/G+UWE/pIfqE3ZfKDt4/18IDBfSn2qHVgu1y0uZJeyUk1Og7fJeLHt92FA+yJPTyjnyBiw7VULk1q1O6W+EmZFReJUI3q9KM1KiAt8V6xrAw2rGWEQ23HqT9zEJ9JTyCHMZ9Eu3C415P81bEfJFvnmwBaf2rp2T+Pfeq1BwQvRhO3ajLukqx497+UItOKf8INWjSD67yc5I5F4Bma1v7fO31I8Gh+aMHwrcpyfxFyT14GuyOmvDx+lTeVNka/irWX78IDSKE0mRV5LOlAzEp5qGN2ugTQV1Y5ORs/Ji6wWOFQBXP8PxaSjNgOprp3i4+m13Kf/aBQGw/gk3bOZf/lYrVaUiXmjy/jClEboyh5TY1U+gdhMOfl3XI3JjZ6jkwIYqdo9olPCHTzPIDKAgRD6RUPnbvctfvTToPGXrYlc6T99AYVCFj5RqgEUWxQOZhNollRyWYLGeACjWsngpR1z1+x8cVfMVwQXQMnu3BFWWM96vCTKXNnn6+0MuClvTjI1kKOT3JX2NOaC+y28DBibZCd1FCqMjKgCFq7Ex26AAp7Q2n49Ro61kNDaa2FSSFgYFLLC8zttw== cardno:36_048_366"
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
