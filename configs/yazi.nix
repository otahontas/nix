{ pkgs, ... }:
let
  relative-motions = pkgs.fetchFromGitHub {
    owner = "dedukun";
    repo = "relative-motions.yazi";
    rev = "a603d9e";
    hash = "sha256-9i6x/VxGOA3bB3FPieB7mQ1zGaMK5wnMhYqsq4CvaM4=";
  };
  rose-pine = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "yazi";
    rev = "fd385266af5f3419657e449607f3e87f062d0d2e";
    hash = "sha256-3j7TTtzG+GCB4uVeCiuvb/0dCkHPz7X+MDBVVUp646A=";
  };
in
{
  programs.yazi = {
    enable = true;

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

    flavors = {
      rose-pine-dawn = "${rose-pine}/flavors/rose-pine-dawn.yazi";
    };

    theme = {
      flavor = {
        use = "rose-pine-dawn";
      };
    };
  };
}
