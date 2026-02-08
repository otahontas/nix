_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./config.fish;
    functions = {
      "admin-shell" = {
        description = "Start clean login shell as otahontas-admin";
        body = builtins.readFile ./admin-shell.fish;
      };
    };
  };
}
