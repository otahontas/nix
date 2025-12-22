{
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  safeChain = inputs.safe-chain-nix.lib.${system}.safeChain;
  aikido = "${safeChain.package}/bin";
in
{
  home.packages = [
    safeChain.package
  ];

  programs.nushell.extraConfig = builtins.readFile (
    pkgs.replaceVars ./safe-chain.nu.in {
      aikido_npm = "${aikido}/aikido-npm";
      aikido_npx = "${aikido}/aikido-npx";
      aikido_yarn = "${aikido}/aikido-yarn";
      aikido_pnpm = "${aikido}/aikido-pnpm";
      aikido_pnpx = "${aikido}/aikido-pnpx";
      aikido_bun = "${aikido}/aikido-bun";
      aikido_bunx = "${aikido}/aikido-bunx";
      aikido_pip = "${aikido}/aikido-pip";
      aikido_pip3 = "${aikido}/aikido-pip3";
    }
  );
}
