{ google-workspace-cli, system, ... }:
{
  home.packages = [ google-workspace-cli.packages.${system}.gws ];
}
