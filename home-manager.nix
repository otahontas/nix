{ inputs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
    users.otahontas = import ./home.nix;
  };
}
