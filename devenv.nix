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
      description = "Update home and system flake lockfiles, devenv, and pi agent";
      exec = ''
        nix flake update --flake ./home
        nix flake update --flake ./system
        devenv update
        pi -p "Check if @mariozechner/pi-coding-agent has a newer version on npm than what's in home/configs/pi-coding-agent/pi-package/package.json. If newer: update version in package.json, run 'npm install --prefix home/configs/pi-coding-agent/pi-package', update version and npmDepsHash in home/configs/pi-coding-agent/default.nix (get npmDepsHash by setting it to empty string and running nix-build to see the expected hash in the error message)."
      '';
    };
  };
}
