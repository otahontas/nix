# Plugin-Style Tool Configuration Design

## Goal

Restructure nix-darwin config so each tool "plugs itself" into the system. When you install a tool, all its configuration (packages, settings, shell integrations) lives in one place instead of scattered across multiple files.

## Design Principles

1. **Self-contained tools**: Each tool module contains everything about that tool
2. **Auto-discovery**: Shell integrations load automatically without manual registration
3. **Simple ownership**: If code is about a specific tool, it lives with that tool
4. **Declarative**: Adding a tool = create configs/tool/ and import it

## File Structure

```
configs/
  git/
    git.nix           # Tool config + packages
    git.nu            # Nushell shell integration
    lefthook.yml      # Other tool files
    commitlint.config.mjs

  bat/
    bat.nix
    bat.nu            # alias cat = bat

  docker/
    docker.nix
    docker.nu         # Optional - only if tool needs shell integration

  mise/
    mise.nix          # Some tools won't need .nu files (use built-in integration)

  nushell/
    nushell.nix       # Program config + auto-discovery logic
    nushell.nu        # Core nushell config (generic shell helpers only)
```

## Pattern Per Tool

1. `tool.nix` - Package installation, program configuration, file deployments
2. `tool.nu` (optional) - Nushell aliases, functions, completions for that tool
3. Tools remain independent modules - add/remove via home.nix imports

## Auto-Discovery Implementation

**nushell.nix discovers and loads all .nu files:**

```nix
{ pkgs, config, lib, ... }:
let
  # Find all .nu files in configs/*/ directories
  configsDir = ./.;

  # Get all subdirectories in configs/
  toolDirs = builtins.readDir configsDir;

  # For each tool dir, check if tool.nu exists and read it
  collectNuFiles = lib.attrsets.mapAttrsToList (name: type:
    let
      nuFile = configsDir + "/${name}/${name}.nu";
    in
      if type == "directory" && builtins.pathExists nuFile
      then builtins.readFile nuFile
      else ""
  ) toolDirs;

  # Combine all tool integrations
  allIntegrations = lib.concatStrings collectNuFiles;
in
{
  home.packages = with pkgs; [
    carapace
    (llm.withPlugins { llm-cmd = true; })
  ];

  catppuccin.nushell.enable = true;

  programs.nushell = {
    enable = true;

    # Keep env setup centralized
    extraEnv = ''
      # PATH, VISUAL, EDITOR, DOCKER_HOST, etc.
    '';

    # Auto-load all tool integrations
    extraConfig = allIntegrations;
  };
}
```

**Loading order**: Alphabetical by tool name. Simple, predictable. Last-wins on conflicts.

**Environment variables**: Stay centralized in nushell.nix for now (YAGNI).

## Content Ownership

**What goes in tool.nu:**
- Aliases for that tool (git aliases in git.nu, bat alias in bat.nu)
- Tool-specific functions (git worktree functions in git.nu)
- Tool-specific completions or helpers

**What stays in nushell.nu:**
- Generic directory helpers (mcd, cl)
- Generic date helpers (week, today)
- Prompt configuration
- Shell-level configuration

**Rule**: If it's about a specific tool, it belongs in that tool's .nu file.

## Migration Path

1. **Restructure git:**
   - Move configs/git.nix → configs/git/git.nix
   - Extract git worktree functions → configs/git/git.nu
   - Extract git aliases (gsw, etc.) → configs/git/git.nu

2. **Restructure other tools:**
   - Create configs/bat/bat.nu with `alias cat = bat`
   - Create configs/ls/ (or eza/) with ll, la aliases
   - Extract tool-specific content to respective tool.nu files

3. **Update nushell:**
   - Rename configs/nushell/config.nu → configs/nushell/nushell.nu
   - Remove tool-specific content (now in tool.nu files)
   - Keep only generic shell helpers
   - Update configs/nushell.nix → configs/nushell/nushell.nix
   - Add auto-discovery logic

4. **Update imports:**
   - Update home.nix with new paths

5. **Test:**
   - Run `mise run build`
   - Verify all aliases and functions work

## Future Expansion

**Other shells (bash, zsh):**
- Add tool.bash, tool.zsh files
- Extend auto-discovery to load those files into respective shells
- Same pattern, more file types

**Environment variables per tool:**
- Add tool.env.nu support if centralized env becomes painful
- Auto-discovery loads both tool.nu and tool.env.nu

## Benefits

1. **Easier to understand**: All git stuff is in configs/git/
2. **Easier to add tools**: Create directory, add .nu file, done
3. **Easier to remove tools**: Delete directory, remove import
4. **No duplication**: Don't manually list integrations in nushell.nix
5. **Declarative**: System state = set of imported tool modules
