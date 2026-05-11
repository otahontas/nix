_: {
  files = {
    ".typos.toml".text = ''
      [default.extend-words]
      # Home Assistant abbreviation
      hass = "hass"
      # Universal Plug and Play
      Pn = "Pn"
      # Proper name (sculptor in Browning's "My Last Duchess")
      Claus = "Claus"

      [type.md]
      extend-ignore-re = [
        "nix-[a-z0-9]{4}\\.md",
        "(?m)^id:\\s+nix-[a-z0-9]{4}$",
      ]

      [type.asc]
      extend-glob = ["*.asc"]
      check-file = false
    '';
  };

  devenv-base.treefmt = {
    settings.global.excludes = [
      "home/configs/git/allowed_signers"
      "home/configs/neovim/nvim/spell/en.utf-8.add"
      "system/keyboard/*.keylayout"
    ];
    programs = {
      fish_indent.enable = true;
    };
  };

  tasks = {
    "home:apply" = {
      description = "Apply home-manager configuration from ./home flake";
      exec = "home-manager switch --flake ./home";
    };
    "system:apply" = {
      description = "Apply system from ./system flake";
      exec = "sudo darwin-rebuild switch --flake ./system";
    };
    "nix:update" = {
      description = "Update home and system flake lockfiles, devenv, and manually-pinned packages";
      exec = ''
        nix flake update --flake ./home
        nix flake update --flake ./system
        devenv update
        pi -p "Check these three manually-pinned packages for newer versions and update them if newer exists. DO NOT apply any changes (no home-manager switch, no nix-build). DO NOT commit. ONLY update the source files — nothing else.

        1. pi-coding-agent (configs/pi-coding-agent): check npm for @mariozechner/pi-coding-agent newer than version in pi-package/package.json. If newer: update version in package.json, run 'npm install --prefix home/configs/pi-coding-agent/pi-package', update version and npmDepsHash in default.nix (set npmDepsHash empty, nix-build to get expected hash from error).

        2. pi-mcp-adapter (packages/pi-mcp-adapter.nix): check GitHub releases at nicobailon/pi-mcp-adapter for version newer than what's in the nix file. If newer: update version, rev, src hash, and npmDepsHash in packages/pi-mcp-adapter.nix (same hash technique).

        3. pi-web-access (packages/pi-web-access.nix): check GitHub releases at nicobailon/pi-web-access for version newer than what's in the nix file. If newer: update version, rev, src hash, and npmDepsHash in packages/pi-web-access.nix (same hash technique)."
      '';
    };
  };
}
