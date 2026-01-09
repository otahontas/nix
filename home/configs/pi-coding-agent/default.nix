{ pkgs, ... }:

{
  home = {
    # Install pi package with Node.js wrapper
    packages = [
      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:$PATH"
        exec npx @mariozechner/pi-coding-agent "$@"
      '')
    ];

    # Deploy files
    file = {
      # AGENTS.md
      ".pi/agent/AGENTS.md".source = ./AGENTS.md;

      # Extensions
      ".pi/agent/extensions/coding-guardrails.ts".source = ./extensions/coding-guardrails.ts;

      # Skills
      ".pi/agent/skills/catch-up/SKILL.md".source = ./skills/catch-up/SKILL.md;
      ".pi/agent/skills/using-git-worktrees/SKILL.md".source = ./skills/using-git-worktrees/SKILL.md;
    };
  };

  # Fish shell integration
  programs.fish.interactiveShellInit = ''
    # Pi aliases
    alias p='pi'
    alias pc='pi -c'
    alias pr='pi -r'
  '';
}
