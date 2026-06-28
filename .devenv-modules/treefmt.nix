_:

{
  treefmt = {
    enable = true;
    config = {
      settings.global.excludes = [
        "*.lock"
        "*.lockb"
        ".devenv/**"
        ".pi/extensions/lat.ts"
        ".pi/skills/lat-md/SKILL.md"
        "AGENTS.md"
        "home/configs/git/allowed_signers"
        "system/keyboard/*.keylayout"
      ];
      programs = {
        fish_indent.enable = true;
        nixfmt.enable = true;
        prettier.enable = true;
        shfmt.enable = true;
        stylua.enable = true;
        taplo.enable = true;
      };
    };
  };
}
