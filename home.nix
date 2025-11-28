{ lib, ... }:
{
  imports = [
    ./configs/theme.nix
    ./configs/alacritty.nix
    ./configs/awscli/awscli.nix
    ./configs/bat/bat.nix
    ./configs/chordpro.nix
    ./configs/claude.nix
    ./configs/colima.nix
    ./configs/delta.nix
    ./configs/eza/eza.nix
    ./configs/fd/fd.nix
    ./configs/fonts.nix
    ./configs/gfortran.nix
    ./configs/gh/gh.nix
    ./configs/git/git.nix
    ./configs/gnugrep.nix
    ./configs/gpg.nix
    ./configs/keyboard.nix
    ./configs/mise.nix
    ./configs/neovim/neovim.nix
    ./configs/nixfmt.nix
    ./configs/nushell/nushell.nix
    ./configs/qpdf/qpdf.nix
    ./configs/ripgrep.nix
    ./configs/skhd.nix
    ./configs/skim/skim.nix
    ./configs/ssh.nix
    ./configs/starship/starship.nix
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
