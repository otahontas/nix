_: {
  programs.fd = {
    enable = true;
    hidden = true;
  };

  programs.fish.interactiveShellInit = builtins.readFile ./config.fish;
}
