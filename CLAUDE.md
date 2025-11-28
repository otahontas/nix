Nix-darwin system configuration with Nushell shell.

## Testing changes workflow:
1. `mise run format` - format code
2. `git add .` - stage changes (required for flake to see them)
3. `mise run build` - rebuild and apply changes

## Nushell integration patterns:

### Environment variables:
- Use `programs.nushell.extraEnv` in .nix files for Nushell environment variables
- Do NOT use `home.sessionVariables` - it only affects login shells, not Nushell
- Example: `programs.nushell.extraEnv = ''$env.MY_VAR = "value"'';`

### Code structure:
- Each tool has paired files in `configs/toolname/`:
  - `toolname.nix` - package, settings, environment variables (explicitly imported in home.nix)
  - `toolname.nu` - functions, aliases, keybindings (auto-discovered)
- The .nu files are automatically concatenated into Nushell config by `configs/nushell/nushell.nix`
- Never manually import .nu files - the auto-discovery system handles this

### Where things go:
- Environment variables: `.nix` files via `programs.nushell.extraEnv`
- Functions and aliases: `.nu` files
- PATH modifications: Centralized in `configs/nushell/nushell.nix` extraEnv only
- Core shell behavior: `configs/nushell/nushell.nu` (keep minimal, tool-specific stuff goes in tool dirs)

### Adding a new tool:
1. Create `configs/toolname/toolname.nix` - import it in home.nix
2. Create `configs/toolname/toolname.nu` - automatically discovered, no import needed
3. Put static config/env in .nix, runtime Nushell code in .nu
