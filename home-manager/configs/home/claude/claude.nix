{ pkgs, lib, ... }:
let
  claudeWithNode = pkgs.writeShellScriptBin "claude" ''
    export PATH="${pkgs.nodejs_24}/bin:$PATH"
    exec ${lib.getExe pkgs.claude-code} "$@"
  '';

  starshipConfig = ./starship-claude.toml;

  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)
    cwd=$(echo "$input" | ${lib.getExe pkgs.jq} -r '.workspace.current_dir')
    model=$(echo "$input" | ${lib.getExe pkgs.jq} -r '.model.display_name')

    # Run starship with claude-specific config
    prompt=$(STARSHIP_CONFIG="${starshipConfig}" ${lib.getExe pkgs.starship} prompt -p "$cwd" 2>/dev/null | tr -d '\n')

    # Append model name in subtext color
    printf '%s \033[38;2;108;111;133m%s\033[0m' "$prompt" "$model"
  '';

  settingsJson = pkgs.runCommand "claude-settings.json" { } ''
    ${lib.getExe pkgs.jq} --arg cmd "${statuslineScript}" \
      '.statusLine.command = $cmd' \
      ${./settings.json} > $out
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
    ".claude/settings.json".source = settingsJson;
    ".claude/commands/catch-up.md".source = ./commands/catch-up.md;
  }
  // hookMappings;
  programs.nushell = {
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./config/ai-helpers.nu)
      (builtins.readFile ./config/keybindings.nu)
      (builtins.readFile ./config/claude-plugins.nu)
    ];
    shellAliases = {
      c = "claude";
      cc = "claude -c";
      cr = "claude -r";
      colo = "claude --dangerously-skip-permissions";
      ccolo = "claude -c --dangerously-skip-permissions";
      crolo = "claude -r --dangerously-skip-permissions";
    };
  };
}
