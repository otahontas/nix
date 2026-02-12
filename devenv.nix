{ pkgs, inputs, ... }:

let
  treefmt-nix = import inputs.treefmt-nix;
  treefmtEval = treefmt-nix.evalModule pkgs {
    projectRootFile = "devenv.nix";
    settings.global.excludes = [
      "home/configs/git/allowed_signers"
      "home/configs/npm/.npmrc"
      "home/configs/neovim/nvim/spell/en.utf-8.add"
      "system/keyboard/*.keylayout"
    ];
    programs = {
      fish_indent.enable = true;
      nixfmt.enable = true;
      prettier.enable = true;
      shfmt.enable = true;
      stylua.enable = true;
      taplo.enable = true;
    };
  };
in
{
  packages = [
    treefmtEval.config.build.wrapper
    pkgs.commitlint
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
    "nix:format" = {
      description = "Run treefmt formatters";
      exec = "treefmt -v";
    };
  };

  git-hooks.hooks = {
    check-merge-conflicts.enable = true;
    deadnix.enable = true;
    detect-private-keys.enable = true;
    shellcheck.enable = true;
    statix.enable = true;
    typos.enable = true;
    treefmt = {
      enable = true;
      package = treefmtEval.config.build.wrapper;
    };
    commitlint = {
      enable = true;
      stages = [ "commit-msg" ];
      entry = "${pkgs.commitlint}/bin/commitlint --extends @commitlint/config-conventional --edit";
    };
    gitleaks = {
      enable = true;
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --verbose";
    };
  };
}
