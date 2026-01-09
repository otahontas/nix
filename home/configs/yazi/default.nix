{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins = {
      inherit (pkgs.yaziPlugins) git;
      inherit (pkgs.yaziPlugins) jump-to-char;
      inherit (pkgs.yaziPlugins) relative-motions;
      inherit (pkgs.yaziPlugins) starship;
    };
    settings = {
      mgr = {
        show_hidden = true;
      };
      plugin = {
        prepend_fetchers = [
          {
            id = "git";
            url = "*";
            run = "git";
          }
          {
            id = "git";
            url = "*/";
            run = "git";
          }
        ];
      };
    };
    initLua = ''
      require("git"):setup()
      require("starship"):setup()
    '';
    keymap = {
      mgr.prepend_keymap =
        (builtins.map
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
          ]
        )
        ++ [
          {
            on = [ "f" ];
            run = "plugin jump-to-char";
            desc = "Jump to char";
          }
        ];
    };
  };
}
