Nix-darwin system configuration with Nushell shell.

## Package management
- NEVER install anything through Homebrew
- All packages must be managed through Nix (nix-darwin or home-manager)

## Testing changes
1. `git add .` - stage changes (required for flake to see them)
2. `just apply` - apply configuration

## Code structure
- Tools go in `configs/home/[toolname]/[toolname].nix`
- Nushell configs:
  - Simple env vars: `programs.nushell.environmentVariables`
  - Complex env/config: separate `.nu` files read via `builtins.readFile`

## Nix conventions
- Binaries: `lib.getExe pkgs.tool` or `lib.getExe' pkgs.tool "binary"` for multi-binary packages
- Config files: `xdg.configFile` or `home.file` with `.source`, not inline `text`
- Directories: add `recursive = true`
- Merging attrs: use `//` operator

## Template interpolation
- Files needing nix values: `filename.in` with `@variable@` syntax
- Use `pkgs.replaceVars ./file.in { var = value; }`
- `.in` suffix also useful to prevent tools from detecting config files in source tree
- Example: `configs/home/vivid/vivid.nix`

## Launchd agents
For services needing user environment (secrets, GPG, password-store):
- Use `RunAtLoad = true` (runs after login with full env access)
- Examples: `configs/home/awscli/awscli.nix`, `configs/home/colima/colima.nix`

## Activation scripts
For one-time setup after files are written, use `lib.hm.dag.entryAfter [ "writeBoundary" ]`
- Example: `configs/home/colima/colima.nix`
