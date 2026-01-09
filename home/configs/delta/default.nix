_: {
  catppuccin.delta.enable = true;
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      hyperlinks = true;
      navigate = true;
      side-by-side = true;
    };
  };
}
