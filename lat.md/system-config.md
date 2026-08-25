# System config

nix-darwin owns macOS defaults, accounts, firewall, Nix daemon settings, keyboard data, and Mac App Store declarations. Applying it requires sudo and remains a user action.

## System ownership

System configuration is limited to state that requires machine-wide or nix-darwin ownership.

This includes macOS UI and input defaults, Touch ID sudo, firewall policy, Nix daemon settings, Fish as the default shell, keyboard layouts, and declarative Mac App Store apps.

User tools and suitable app bundles belong to Home Manager; vendor software with privileged installers remains manual.

## Manual applications

Vendor-managed software stays outside Nix when installers own drivers, plug-ins, content, privileged helpers, updates, or license state.

Brew-nix casks installed through `home.packages` remain Home Manager-owned per [[home-configs#Patterns]]. Package availability alone does not justify split ownership.

Surprising exceptions where a package exists but manual ownership still wins:

- **OrbStack** — relocation, privileged helpers, and global CLI links expect system locations.
- **Arturia Software Center** — the packaged manager does not reproduce vendor scripts or required `/Library` resources.
- **Native Access** — the packaged manager does not own downstream product installers, content, helpers, updates, or licenses.

Other vendor audio software stays manual under the same rule; absent packages do not need an inventory here.

## Keyboard layout file

The custom keylayout is generated Apple keyboard data, not ordinary XML configuration.

`system/keyboard/us-international-nodeadkeys.keylayout` contains Apple-valid control references and CR line endings, so generic XML tools and `plutil` are intentionally skipped.
