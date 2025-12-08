Nix-darwin system configuration with Nushell shell.

## Package management:
- NEVER install anything through Homebrew
- All packages must be managed through Nix (nix-darwin or home-manager)

## Testing changes workflow:
1. `mise run verify` - format, check flake, and build (no sudo)
2. `git add .` - stage changes (required for flake to see them)
3. `mise run apply` - apply configuration with sudo (only after verify passes)

Always run `mise run verify` before `mise run apply`. Only apply if verify succeeds.

## Nushell integration patterns:

### Environment variables:
- Use `programs.nushell.extraEnv` in .nix files for Nushell environment variables
- Do NOT use `home.sessionVariables` - it only affects login shells, not Nushell
- Example: `programs.nushell.extraEnv = ''$env.MY_VAR = "value"'';`

### Code structure:
- Each tool has paired files in `configs/home/toolname/`:
  - `toolname.nix` - package, settings, environment variables (auto-discovered)
  - `toolname.nu` - functions, aliases, keybindings (auto-discovered)
- System-level configs go in `configs/system/`
- All .nix files are automatically imported by flake.nix - no manual imports needed
- The .nu files are automatically concatenated into Nushell config by `configs/home/nushell/nushell.nix`

### Where things go:
- Environment variables: `.nix` files via `programs.nushell.extraEnv`
- Functions and aliases: `.nu` files
- PATH modifications: Centralized in `configs/home/nushell/nushell.nix` extraEnv only
- Core shell behavior: `configs/home/nushell/nushell.nu` (keep minimal, tool-specific stuff goes in tool dirs)
- System-level settings: `configs/system/` (nix-darwin settings, defaults, security, etc.)

### Adding a new tool:
1. Create `configs/home/toolname/toolname.nix` - automatically imported by flake.nix
2. Create `configs/home/toolname/toolname.nu` - automatically discovered, no import needed
3. Put static config/env in .nix, runtime Nushell code in .nu

## File management:
- Always prefer separate configuration files over inline text in .nix files
- Use `home.file.".config/tool/config".source = ./path/to/config;` instead of `text = "..."`
- Benefits: syntax highlighting, easier editing, better version control diffs
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
- `configs/home/npm/npm.nix` - sets up npm authentication
- `configs/home/colima/colima.nix` - starts background services
- `configs/home/skhd/skhd.nix` and `configs/home/yabai/yabai.nix` - window manager setup

### When to use this pattern:
- Generating config files from password-store
- Accessing credentials from 1Password
- Any operation requiring GPG decryption
- Scripts that need user's authentication context
