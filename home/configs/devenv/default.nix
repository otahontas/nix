{ pkgs, ... }:
{
  home.packages = [ pkgs.devenv ];

  xdg.configFile."fish/conf.d/devenv-tasks-run.fish".text = builtins.readFile ./devenv-tasks-run.fish;
}
