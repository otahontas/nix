{ pkgs, lib, ... }:
let
  claudeWithNode = pkgs.writeShellScriptBin "claude" ''
    export PATH="${pkgs.nodejs_24}/bin:$PATH"
    exec ${lib.getExe pkgs.claude-code} "$@"
  '';

  hooksDir = ./hooks;
  hookFiles = builtins.attrNames (builtins.readDir hooksDir);
  hookMappings = builtins.listToAttrs (
    map (
      filename:
      let
        hookName = builtins.replaceStrings [ ".md" ] [ "" ] filename;
      in
      {
        name = ".claude/hookify.${hookName}.local.md";
        value = {
          source = "${hooksDir}/${filename}";
        };
      }
    ) hookFiles
  );
in
{
  home.packages = [ claudeWithNode ];

  home.file = {
    ".claude/CLAUDE.md".source = ./CLAUDE.md;
    ".claude/settings.json".source = ./settings.json;
    ".claude/commands/catch-up.md".source = ./commands/catch-up.md;
  }
  // hookMappings;
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
}
