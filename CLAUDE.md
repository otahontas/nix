Nix-darwin system configuration with Nushell shell.

## Package management:
- NEVER install anything through Homebrew
- All packages must be managed through Nix (nix-darwin or home-manager)

## Testing changes workflow:
2. `git add .` - stage changes (required for flake to see them)
3. `just apply` - apply configuration with sudo (only after verify passes)

## Nushell integration patterns:

### Environment variables:
- If there is nushell file `[tool-name].nu`, use that for setting env vars
- Otherwise use `programs.nushell.extraEnv` in .nix files for Nushell environment variables
- Do NOT use `home.sessionVariables` - it only affects login shells, not Nushell
- Example: `programs.nushell.extraEnv = ''$env.MY_VAR = "value"'';`

### Code structure:
- Each tool has paired files in `configs/home/toolname/`:
  - `toolname.nix` - package, settings, environment variables (auto-discovered)
  - If needed: `toolname.nu` - functions, aliases, keybindings (auto-discovered). There are tools that don't need nushell configs.
- System-level configs go in `configs/system/`
- All .nix files are automatically imported by flake.nix - no manual imports needed
- The .nu files are automatically concatenated into Nushell config by `configs/home/nushell/nushell.nix`
- Put static config/env in .nix, runtime Nushell code in .nu

## File management:
- Always prefer separate configuration files over inline text in .nix files
- Use `home.file.".config/tool/config".source = ./path/to/config;` instead of `text = "..."`
- Exception: very short content (1-2 lines) can be inline

## Accessing user secrets in nix-darwin:

### Problem:
- Home-manager activation scripts run during `darwin-rebuild switch` before user login
- They run in restricted environment without GPG agent, password-store, or user environment
- Cannot access secrets during build/activation phase

### Solution: Use launchd agents for secrets access
- Launchd agents with `RunAtLoad = true` run after user login
- They have access to GPG agent, password-store, and full user environment
- Must explicitly set environment variables (they don't inherit shell environment)

### Example implementations:
See these files for working launchd agent patterns:
- `configs/home/awscli/awscli.nix` - generates AWS config from password-store
- `configs/home/colima/colima.nix` - starts background services
