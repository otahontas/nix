{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  safeChain = inputs.safe-chain-nix.lib.${system}.safeChain;
in
{
  home.packages = [
    # Install safe-chain aikido binaries for malware protection with mise-managed node
    safeChain.package
  ];

  programs.nushell.extraEnv = ''
    # Optional: Configure safe-chain logging
    # $env.SAFE_CHAIN_LOG_LEVEL = "verbose"

    # Optional: Configure minimum package age (default: 24h)
    # $env.SAFE_CHAIN_MIN_AGE_HOURS = "24"
  '';
}
