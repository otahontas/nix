Nix-darwin system configuration with Nushell shell.

## Configuration Structure
See [CONFIGURATION.md](CONFIGURATION.md) for detailed information about the two separate flakes.

Quick overview:
- `home/` - Standalone home-manager flake (no sudo, portable)
  - `flake.nix` - Home-manager flake
  - `modules/` - User config (42 tools)
- `darwin/` - Standalone nix-darwin flake (requires sudo, macOS-specific)
  - `flake.nix` - nix-darwin flake
  - `modules/` - System config

## Package management
- NEVER install anything through Homebrew
- All packages must be managed through Nix (nix-darwin or home-manager)
- Prefer home-manager over other nix solutions

## Testing changes
1. `git add .` - stage changes (required for flake to see them)
2. For home-manager: `just apply-home` (no sudo)
3. For nix-darwin: `just apply` (requires sudo)

## Code structure
- User tools go in `home/modules/[toolname]/[toolname].nix`
- System settings go in `darwin/modules/[name].nix`
- Nushell configs:
  - Simple env vars: `programs.nushell.environmentVariables`
  - Complex env/config: separate `.nu` files read via `builtins.readFile`

## Nix conventions
- Binaries: `lib.getExe pkgs.tool` or `lib.getExe' pkgs.tool "binary"` for multi-binary packages
- Config files: `xdg.configFile` or `home.file` with `.source`, not inline `text`
- Directories: add `recursive = true`
- Merging attrs: use `//` operator
- Path preference: `config.xdg.*` > `config.home.homeDirectory` > hardcoded paths
- Executable scripts: use `home.file.<path>.executable = true`

## Theming
- Check for catppuccin support when adding new tools: `catppuccin.<tool>.enable = true`
- Example: `home/modules/delta/delta.nix`

## Runtime wrappers
Tools needing isolated runtimes (node, python) use wrapper scripts:
```nix
pkgs.writeShellScriptBin "toolname" ''
  export PATH="${pkgs.nodejs_24}/bin:$PATH"
  exec ${lib.getExe pkgs.actual-tool} "$@"
''
```
- Example: `home/modules/claude/claude.nix`

## Template interpolation
- Files needing nix values: `filename.in` with `@variable@` syntax
- Use `pkgs.replaceVars ./file.in { var = value; }`
- `.in` suffix also useful to prevent tools from detecting config files in source tree
- Example: `home/modules/vivid/vivid.nix`

## Launchd agents
For services needing user environment (secrets, GPG, password-store):
- Use `RunAtLoad = true` (runs after login with full env access)
- Examples: `home/modules/awscli/awscli.nix`, `home/modules/colima/colima.nix`
