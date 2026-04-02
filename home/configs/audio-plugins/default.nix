{ nix-audio-casks, system, ... }:
{
  home.packages = [
    nix-audio-casks.packages.${system}.waves-central
    nix-audio-casks.packages.${system}.native-access
    nix-audio-casks.packages.${system}.arturia-software-center
  ];
}
