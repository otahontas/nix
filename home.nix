{ lib, ... }:
{
  imports = [
    ./configs/theme.nix
    ./configs/alacritty.nix
    ./configs/awscli.nix
    ./configs/bat.nix
    ./configs/claude.nix
    ./configs/colima.nix
    ./configs/delta.nix
    ./configs/fd.nix
    ./configs/fonts.nix
    ./configs/gh.nix
    ./configs/git.nix
    ./configs/gnugrep.nix
    ./configs/gpg.nix
    ./configs/local-scripts.nix
    ./configs/mise.nix
    ./configs/neovim.nix
    ./configs/nixfmt.nix
    ./configs/nushell.nix
    ./configs/ripgrep.nix
    ./configs/skhd.nix
    ./configs/skim.nix
    ./configs/ssh.nix
    ./configs/starship.nix
    ./configs/uv.nix
    ./configs/vivid.nix
    ./configs/wget.nix
    ./configs/yabai.nix
    ./configs/yazi.nix
    ./configs/zellij.nix
    ./configs/zoxide.nix
  ];

  home.username = "otahontas";
  home.homeDirectory = "/Users/otahontas";
  home.stateVersion = "25.05";

  xdg.enable = true;

  home.sessionVariables = {
    VISUAL = lib.mkDefault "vim";
    EDITOR = lib.mkDefault "vim";
  };
}
