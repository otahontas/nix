{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.callPackage ../../packages/ollama-bin.nix { };
  };
}
