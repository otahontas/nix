{ ... }:
{
  catppuccin.delta.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      hyperlinks = true;
    };
  };
}
