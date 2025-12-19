{ pkgs, ... }:
let
  claudeWithNode = pkgs.writeShellScriptBin "claude" ''
    export PATH="${pkgs.nodejs_24}/bin:$PATH"
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';

  hooksDir = ./hooks;
  hookFiles = builtins.attrNames (builtins.readDir hooksDir);
  hookMappings = builtins.listToAttrs (
    map (
      filename:
      let
        # Extract hook name from filename (e.g., "block-claude-attribution.md" -> "block-claude-attribution")
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
}
