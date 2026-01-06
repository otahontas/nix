{ inputs, ... }:
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
      relative-motions = inputs.yazi-relative-motions;
    };
  };
}
