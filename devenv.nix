{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  writeBase64DecodedFile =
    name: contentBase64:
    pkgs.runCommand name
      {
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        ${pkgs.coreutils}/bin/base64 -d ${pkgs.writeText "${name}.b64" contentBase64} > $out
      '';

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

  postEditHookFile = writeBase64DecodedFile "post-edit-hook.ts" ''
    LyoqCiAqIFBvc3QtZWRpdCBob29rIGV4dGVuc2lvbgogKgogKiBSdW5zIHByZWsgaG9va3Mgb24gdGhlIHNwZWNpZmljIGZpbGUg
    YWZ0ZXIgYW55IGZpbGUtbXV0YXRpbmcgdG9vbCBjYWxsLgogKiBJbmplY3RzIGlzc3VlcyBpbnRvIHRoZSB0b29sIHJlc3VsdCBz
    byB0aGUgTExNIGNhbiBmaXggdGhlbSBiZWZvcmUgY29tbWl0dGluZy4KICovCgppbXBvcnQgdHlwZSB7IEV4dGVuc2lvbkFQSSB9
    IGZyb20gIkBtYXJpb3plY2huZXIvcGktY29kaW5nLWFnZW50IjsKCmNvbnN0IEZJTEVfTVVUQVRJTkdfVE9PTFMgPSBuZXcgU2V0
    KFsiZWRpdCIsICJ3cml0ZSJdKTsKCmV4cG9ydCBkZWZhdWx0IGZ1bmN0aW9uIChwaTogRXh0ZW5zaW9uQVBJKSB7CiAgcGkub24o
    InRvb2xfcmVzdWx0IiwgYXN5bmMgKGV2ZW50LCBjdHgpID0+IHsKICAgIGlmICghRklMRV9NVVRBVElOR19UT09MUy5oYXMoZXZl
    bnQudG9vbE5hbWUudG9Mb3dlckNhc2UoKSkpIHJldHVybjsKICAgIGlmIChldmVudC5pc0Vycm9yKSByZXR1cm47CgogICAgY29u
    c3QgZmlsZVBhdGggPSAoZXZlbnQuaW5wdXQgYXMgYW55KT8ucGF0aDsKICAgIGlmICghZmlsZVBhdGgpIHJldHVybjsKCiAgICBj
    b25zdCBkZXZlbnZSb290ID0gcHJvY2Vzcy5lbnYuREVWRU5WX1JPT1QgPz8gY3R4LmN3ZDsKCiAgICAvLyBSZXNvbHZlIHRvIHJl
    bGF0aXZlIHBhdGggZm9yIHByZWsKICAgIGxldCByZWxQYXRoID0gZmlsZVBhdGg7CiAgICBpZiAoZmlsZVBhdGguc3RhcnRzV2l0
    aChkZXZlbnZSb290ICsgIi8iKSkgewogICAgICByZWxQYXRoID0gZmlsZVBhdGguc2xpY2UoZGV2ZW52Um9vdC5sZW5ndGggKyAx
    KTsKICAgIH0KCiAgICBjb25zdCByZXN1bHQgPSBhd2FpdCBwaS5leGVjKAogICAgICAiYmFzaCIsCiAgICAgIFsKICAgICAgICAi
    LWMiLAogICAgICAgIGBjZCAiJHtkZXZlbnZSb290fSIgJiYgLmRldmVudi9wcm9maWxlL2Jpbi9wcmVrIHJ1biAtLWZpbGVzICIk
    e3JlbFBhdGh9ImAsCiAgICAgIF0sCiAgICAgIHsKICAgICAgICB0aW1lb3V0OiAzMDAwMCwKICAgICAgfSwKICAgICk7CgogICAg
    aWYgKHJlc3VsdC5jb2RlICE9PSAwKSB7CiAgICAgIC8vIHByZWsgcmVzdWx0cyBhcmUgaW4gc3Rkb3V0IChkZXZlbnYgLS1xdWll
    dCBzdXBwcmVzc2VzIHNoZWxsIHNldHVwIG5vaXNlKQogICAgICBjb25zdCBvdXRwdXQgPSAocmVzdWx0LnN0ZG91dCB8fCAiIiku
    dHJpbSgpOwogICAgICBjb25zdCBmYWlsdXJlcyA9IG91dHB1dAogICAgICAgIC5zcGxpdCgiXG4iKQogICAgICAgIC5maWx0ZXIo
    KGxpbmUpID0+IGxpbmUuaW5jbHVkZXMoIkZhaWxlZCIpKQogICAgICAgIC5tYXAoKGxpbmUpID0+IGxpbmUudHJpbSgpKQogICAg
    ICAgIC5qb2luKCJcbiIpOwoKICAgICAgY29uc3QgbXNnID0gZmFpbHVyZXMgfHwgb3V0cHV0LnNsaWNlKDAsIDUwMCk7CgogICAg
    ICBjdHgudWkubm90aWZ5KGBwcmVrIGlzc3VlczogJHttc2cuc2xpY2UoMCwgMzAwKX1gLCAid2FybiIpOwoKICAgICAgLy8gSW5q
    ZWN0IGludG8gdG9vbCByZXN1bHQgc28gdGhlIExMTSBzZWVzIHRoZSBpc3N1ZXMgYW5kIGNhbiBmaXggdGhlbQogICAgICByZXR1
    cm4gewogICAgICAgIGNvbnRlbnQ6IFsKICAgICAgICAgIC4uLmV2ZW50LmNvbnRlbnQsCiAgICAgICAgICB7CiAgICAgICAgICAg
    IHR5cGU6ICJ0ZXh0IiBhcyBjb25zdCwKICAgICAgICAgICAgdGV4dDogYOKaoO+4jyBwcmVrIGZvdW5kIGlzc3VlcyB3aXRoIHRo
    aXMgZmlsZSAoYXV0by1mb3JtYXR0aW5nIG1heSBoYXZlIGJlZW4gYXBwbGllZCwgYnV0IHNvbWUgY2hlY2tzIGZhaWxlZCk6XG4k
    e21zZ31gLAogICAgICAgICAgfSwKICAgICAgICBdLAogICAgICB9OwogICAgfQogIH0pOwp9Cg==
  '';

  gitignoreFile = pkgs.writeText "gitignore" (
    "### repo devenv gitignore\n"
    + (lib.concatStringsSep "\n" [
      ".devenv*"
      ".gitignore"
      ".nvim.lua"
      ".pre-commit-config.yaml"
      ".pi"
      "devenv.local.nix"
      "devenv.local.yaml"
      "lat.md/.cache/"
      "result"
    ])
    + "\n"
    + "### end\n"
    + (lib.optionalString (config.repoDevenv.gitignore.extraEntries != [ ]) (
      "\n" + lib.concatStringsSep "\n" config.repoDevenv.gitignore.extraEntries + "\n"
    ))
  );

  nvimConfig =
    let
      baseLsps = [
        "nixd"
        "bashls"
      ];
      baseLines = [
        "vim.cmd([[set runtimepath+=.nvim]])"
      ]
      ++ map (lsp: ''vim.lsp.enable("${lsp}")'') baseLsps;
      extraLines =
        map (lsp: ''vim.lsp.enable("${lsp}")'') config.repoDevenv.nvim.extraLsps
        ++ lib.optional (config.repoDevenv.nvim.extraConfig != "") config.repoDevenv.nvim.extraConfig;
    in
    "-- ### repo devenv nvim\n"
    + lib.concatStringsSep "\n" baseLines
    + "\n"
    + "-- ### end\n"
    + lib.optionalString (extraLines != [ ]) ("\n" + lib.concatStringsSep "\n" extraLines + "\n");

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

    mkdir -p "$root/.pi/extensions"
    safe_ln ${mcpConfig} "$root/.pi/mcp.json"
    safe_ln ${postEditHookFile} "$root/.pi/extensions/post-edit-hook.ts"

    if ! cmp -s ${gitignoreFile} "$root/.gitignore"; then
      chflags nouchg "$root/.gitignore" 2>/dev/null || true
      install -m 444 ${gitignoreFile} "$root/.gitignore"
      chflags uchg "$root/.gitignore" 2>/dev/null || true
    fi
  '';
in
{
  options.repoDevenv = {
    ai.mcp.extraServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
    };

    gitignore.extraEntries = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    nvim = {
      extraLsps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };
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

    files = {
      ".nvim.lua".text = nvimConfig;
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

    repoDevenv.treefmt = {
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
        excludes = [ "\\.tickets/" ];
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
      };
    };
  };
}
