{ pkgs, ... }:
{
  home.packages = [ pkgs.devenv ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  xdg.configFile."fish/conf.d/devenv-tasks-run.fish".text = builtins.readFile ./devenv-tasks-run.fish;
}
