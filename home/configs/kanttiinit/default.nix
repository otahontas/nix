{ kanttiinit-cli, system, ... }:
{
  home.packages = [ kanttiinit-cli.packages.${system}.default ];
}
