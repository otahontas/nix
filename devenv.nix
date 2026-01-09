{ pkgs, inputs, ... }:

let
  treefmt-nix = import inputs.treefmt-nix;
  treefmtEval = treefmt-nix.evalModule pkgs {
    projectRootFile = "devenv.nix";
    settings.global.excludes = [
      "home/configs/git/allowed_signers"
      "home/configs/npm/.npmrc"
      "system/keyboard/*.keylayout"
    ];
    programs = {
      fish_indent.enable = true;
      just.enable = true;
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
