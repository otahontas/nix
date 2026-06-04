{
  pkgs,
  config,
  ...
}:
{
  env.LAT_LLM_KEY = config.secretspec.secrets.LAT_LLM_KEY;

  packages = [
    pkgs.secretspec
  ];

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
      description = "Update flakes, devenv, home-manager, and pi extensions";
      exec = ''
        nix flake update --flake ./home
        nix flake update --flake ./system
        devenv update
        devenv tasks run home:apply && pi update --extensions
      '';
    };
  };
}
