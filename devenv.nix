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

      [type.md]
      extend-ignore-re = [
        "nix-[a-z0-9]{4}\\.md",
        "(?m)^id:\\s+nix-[a-z0-9]{4}$",
      ]
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
      description = "Update home and system flake lockfiles, devenv and manual packages";
      exec = ''
        nix flake update --flake ./home
        nix flake update --flake ./system
        devenv update
        bash scripts/update-manual-pkgs.sh
      '';
    };
    "nix:format" = {
      description = "Run treefmt formatters";
      exec = "treefmt -v";
    };
  };
}
