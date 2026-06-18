{ pkgs, ... }:

{
  packages = with pkgs; [
    fish-lsp
    taplo
    vscode-langservers-extracted
    yaml-language-server
  ];

  treefmt = {
    enable = true;
    config = {
      settings.global.excludes = [
        "*.lock"
        "*.lockb"
        ".devenv*"
        ".pi/extensions/lat.ts"
        ".pi/skills/lat-md/SKILL.md"
        "AGENTS.md"
        "home/configs/git/allowed_signers"
        "home/configs/neovim/nvim/spell/en.utf-8.add"
        "system/keyboard/*.keylayout"
      ];
      programs = {
        fish_indent.enable = true;
        nixfmt.enable = true;
        prettier.enable = true;
        shfmt.enable = true;
        taplo.enable = true;
      };
    };
  };

  languages = {
    nix.enable = true;
    shell.enable = true;
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
    "nix:format" = {
      description = "Run treefmt formatters";
      exec = "treefmt -v";
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

  git-hooks.hooks = {
    check-merge-conflicts.enable = true;
    deadnix.enable = true;
    detect-private-keys.enable = true;
    shellcheck = {
      enable = true;
      entry = "${pkgs.shellcheck}/bin/shellcheck --severity=warning";
    };
    fish-syntax = {
      enable = true;
      entry = "${pkgs.writeShellScript "fish-syntax-check" ''
        set -euo pipefail
        for file in "$@"; do
          ${pkgs.fish}/bin/fish --no-execute "$file"
        done
      ''}";
      files = "\\.fish$";
      types = [ "file" ];
    };
    json-syntax = {
      enable = true;
      entry = "${pkgs.jq}/bin/jq empty";
      files = "\\.json$";
      types = [ "file" ];
    };
    toml-lint = {
      enable = true;
      entry = "${pkgs.taplo}/bin/taplo lint";
      files = "\\.toml$";
      types = [ "file" ];
    };
    typos = {
      enable = true;
      excludes = [
        "\\.tickets/"
        "^AGENTS\\.md$"
      ];
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
    statix = {
      enable = true;
      entry = "${pkgs.statix}/bin/statix check --format errfmt --ignore .devenv,.devenv.* .";
      pass_filenames = false;
    };
    treefmt.enable = true;
    yamllint = {
      enable = true;
      settings.preset = "relaxed";
    };
  };
}
