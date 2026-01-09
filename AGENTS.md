Nix setup for macOS with strict user separation:

## User separation

- **Admin user** (`otahontas-admin`) - only account with sudo access (by design)
  - Manages nix-darwin config in `system/` folder
  - Installs all graphical programs via Homebrew
- **Primary user** (`otahontas`) - day-to-day account without sudo
  - Manages home-manager config in `home/` folder
  - Installs all CLI tools via home-manager

## Installation guidelines

- **CLI tools** → home-manager (primary user)
- **Graphical apps** → Homebrew through nix-darwin (admin user)
- **Never use `brew` CLI directly** - always configure through nix-darwin
