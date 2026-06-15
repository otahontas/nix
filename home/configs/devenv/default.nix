{ pkgs, ... }:
{
  home.packages = [ pkgs.devenv ];

  programs.fish.interactiveShellInit = builtins.readFile ./devenv.fish;

  # TODO: test if still needed
  xdg.configFile."fish/conf.d/devenv-tasks-run.fish".text = builtins.readFile ./devenv-tasks-run.fish;
}
