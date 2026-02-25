{
  pkgs,
  ...
}:
{
  files = {
    ".typos.toml".text = ''
      [default.extend-words]
      # Home Assistant abbreviation
      hass = "hass"
      # Universal Plug and Play
      Pn = "Pn"
      # Proper name (sculptor in Browning's "My Last Duchess")
      Claus = "Claus"
    '';
  };

  devenv-base.treefmt = {
    settings.global.excludes = [
      "home/configs/git/allowed_signers"
      "home/configs/npm/.npmrc"
      "home/configs/neovim/nvim/spell/en.utf-8.add"
      "system/keyboard/*.keylayout"
    ];
    programs = {
      fish_indent.enable = true;
      shfmt.enable = true;
      stylua.enable = true;
    };
  };

  packages = [
    pkgs.nix-update
  ];

  tasks = {
    "home:apply" = {
      description = "Apply home-manager configuration from ./home flake";
      exec = "home-manager switch --flake ./home";
    };
    "nix:update" = {
      description = "Update root, home, and system flake lockfiles";
      exec = ''
        nix flake update
        nix flake update --flake ./home
        nix flake update --flake ./system
      '';
    };
    "nix:update-manual" = {
      description = "Update manual package definitions (versions & hashes)";
      exec = "bash scripts/update-manual-pkgs.sh";
    };
    "nix:format" = {
      description = "Run treefmt formatters";
      exec = "treefmt -v";
    };
  };
}
