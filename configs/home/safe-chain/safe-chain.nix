{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  safeChain = inputs.safe-chain-nix.lib.${system}.safeChain;
in
{
  home.packages = [
    safeChain.package
  ];
}
