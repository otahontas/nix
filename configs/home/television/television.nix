{ ... }:
{
  catppuccin.television.enable = true;
  programs.television.enable = true;
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
  xdg.configFile."television/cable/nu-history.toml".source = ./nu-history.toml;
  xdg.configFile."television/cable/gh-prs.toml".source = ./gh-prs.toml;
  xdg.configFile."television/cable/gh-runs.toml".source = ./gh-runs.toml;
}
