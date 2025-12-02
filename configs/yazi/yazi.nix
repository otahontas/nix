{ pkgs, ... }:
let
  relative-motions = pkgs.fetchFromGitHub {
    owner = "dedukun";
    repo = "relative-motions.yazi";
    rev = "a603d9e";
    hash = "sha256-9i6x/VxGOA3bB3FPieB7mQ1zGaMK5wnMhYqsq4CvaM4=";
  };
in
{
  catppuccin.yazi.enable = true;
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      mgr = {
        show_hidden = true;
      };
    };
    keymap = {
      mgr.prepend_keymap =
        builtins.map
          (n: {
            on = [ (toString n) ];
            run = "plugin relative-motions ${toString n}";
            desc = "Move in relative steps";
          })
          [
            1
            2
            3
            4
            5
            6
            7
            8
            9
          ];
    };
    plugins = {
      relative-motions = relative-motions;
    };
  };
}
