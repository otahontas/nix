# Home Manager Configuration

This is a standalone home-manager flake for user-level configuration.

## Usage

```bash
cd /path/to/repo/home-manager
git add .  # Required for flake to see uncommitted changes
home-manager switch --flake .#otahontas
```

No sudo required!

## What's Included

All user-level configuration:
- Shell (Nushell)
- Editor (Neovim)
- CLI tools (fzf, bat, fd, ripgrep, etc.)
- Git configuration
- Development tools
- Themes and fonts
- And more...

## Structure

```
.
├── flake.nix           # Home-manager flake
├── flake.lock          # Independent lock file
└── configs/
    └── home/           # User-level modules
        └── [tool]/     # Individual tool configurations
            └── [tool].nix
```

## Benefits

- **No sudo required**: Apply changes without root privileges
- **Fast**: Smaller rebuilds, faster iterations
- **Portable**: Can be used on any machine with Nix
- **Independent**: Doesn't affect system configuration
- **Safe**: Changes are user-scoped only

## Tips

- Most day-to-day changes should go here, not in the system config
- Update frequently without worrying about system stability
- Test changes quickly with `home-manager switch`
- Use `home-manager generations` to see history
- Rollback with `home-manager switch --rollback` if needed
