{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  treefmt-nix = import inputs.treefmt-nix;
  treefmtEval = treefmt-nix.evalModule pkgs {
    imports = [
      {
        projectRootFile = "devenv.nix";
        settings.global.excludes = [
          "*.lock"
          "*.lockb"
          ".devenv*"
          "package-lock.json"
          "pnpm-lock.yaml"
        ];
        programs = {
          nixfmt.enable = true;
          prettier.enable = true;
          shfmt.enable = true;
        };
      }
      config.repoDevenv.treefmt
    ];
  };

  baseMcpServers = {
    "mcp.devenv.sh" = {
      type = "http";
      url = "https://mcp.devenv.sh";
    };
  };
  mcpConfig = pkgs.writeText "mcp.json" (
    builtins.toJSON { mcpServers = baseMcpServers // config.repoDevenv.ai.mcp.extraServers; }
  );

  piUidotshInstall = pkgs.writeShellScriptBin "pi-uidotsh-install" ''
    set -euo pipefail

    token="$(${pkgs.pass}/bin/pass show api/uidotsh)"
    if [ -z "$token" ]; then
      echo "No ui.sh token found in api/uidotsh" >&2
      exit 1
    fi

    export PATH="${pkgs.nodejs}/bin:$PATH"
    exec npm exec --yes @uidotsh/install -- --token "$token"
  '';

  enterShellScript = pkgs.writeShellScript "repo-devenv-enter-shell" ''
    set -euo pipefail

    safe_ln() {
      local src="$1" dest="$2"
      local dir base name ext

      dir="$(dirname "$dest")"
      base="$(basename "$dest")"

      [ -L "$dest" ] && unlink "$dest"

      if [[ $base == *.* ]]; then
        name="''${base%.*}"
        ext=".''${base##*.}"
      else
        name="$base"
        ext=""
      fi

      find "$dir" -maxdepth 1 -type l \
        \( -name "$name $ext" -o -name "$name [0-9]*$ext" \) \
        -delete 2>/dev/null || true

      ln -s "$src" "$dest"
    }

    root="''${DEVENV_ROOT:-$PWD}"

    mkdir -p "$root/.pi"
    safe_ln ${mcpConfig} "$root/.pi/mcp.json"
  '';
in
{
  options.repoDevenv = {
    ai.mcp.extraServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
    };

    treefmt = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = {
    languages = {
      nix.enable = true;
      shell.enable = true;
    };

    packages = [
      treefmtEval.config.build.wrapper
      piUidotshInstall
    ];

    claude.code.enable = lib.mkForce false;

    enterShell = "bash ${enterShellScript}";

    repoDevenv.treefmt = {
      settings.global.excludes = [
        "home/configs/git/allowed_signers"
        "home/configs/neovim/nvim/spell/en.utf-8.add"
        "system/keyboard/*.keylayout"
        ".pi/extensions/lat.ts"
        "AGENTS.md"
        ".pi/skills/lat-md/SKILL.md"
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
      treefmt = {
        enable = true;
        package = treefmtEval.config.build.wrapper;
        excludes = [ "^AGENTS\\.md$" ];
      };
    };
  };
}
