# System config

nix-darwin owns macOS defaults, accounts, firewall, Nix daemon settings, keyboard data, and Mac App Store declarations. Applying it requires sudo and remains a user action.

## System ownership

System configuration is limited to state that requires machine-wide or nix-darwin ownership.

This includes macOS UI and input defaults, Touch ID sudo, firewall policy, Nix daemon settings, Fish as the default shell, keyboard layouts, and declarative Mac App Store apps.

User CLI tools, services, and selected app settings belong to Home Manager; GUI app bundles remain outside Nix.

Only selected App Store apps in `system/flake.nix` are provisioned through `programs.mas.packages`; nix-darwin does not run App Store updates.

## Manual applications

GUI applications are installed and updated outside Nix in `/Applications`; Mac App Store declarations remain under nix-darwin.

Home Manager retains selected app settings and file associations per [[home-configs#Patterns]], but does not install, copy, or link app bundles.

Vendor installers also own drivers, plug-ins, content, privileged helpers, and license state:

- **OrbStack** — relocation, privileged helpers, and global CLI links expect system locations.
- **Arturia Software Center** — the packaged manager does not reproduce vendor scripts or required `/Library` resources.
- **Native Access** — the packaged manager does not own downstream product installers, content, helpers, updates, or licenses.

Other vendor audio software stays manual under the same rule; absent packages do not need an inventory here.

## Keyboard layout file

The custom keylayout is generated Apple keyboard data, not ordinary XML configuration.

`system/keyboard/us-international-nodeadkeys.keylayout` contains Apple-valid control references and CR line endings, so generic XML tools and `plutil` are intentionally skipped.
