_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;
  };

  xdg.configFile."fish/completions/pass.fish".source = ./completions/pass.fish;
}
