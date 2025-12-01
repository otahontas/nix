Nix-darwin system configuration with Nushell shell.

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

### Example pattern:
```nix
launchd.agents.my-secret-script = {
  enable = true;
  config = {
    ProgramArguments = [ "${pkgs.nushell}/bin/nu" "/path/to/script.nu" ];
    EnvironmentVariables = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.local/share/password-store";
      HOME = config.home.homeDirectory;
    };
    RunAtLoad = true;
    StandardOutPath = "/tmp/my-script.out.log";
    StandardErrorPath = "/tmp/my-script.err.log";
  };
};
```

### When to use this pattern:
- Generating config files from password-store
- Accessing credentials from 1Password
- Any operation requiring GPG decryption
- Scripts that need user's authentication context
