{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.repoDevenv.gitignore.extraEntries = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config =
    let
      baseEntries = [
        ".devenv*"
        ".gitignore"
        ".nvim.lua"
        ".pre-commit-config.yaml"
        ".pi"
        "devenv.local.nix"
        "devenv.local.yaml"
        "lat.md/.cache/"
        "result"
      ];
      gitignoreFile = pkgs.writeText "gitignore" (
        "### repo devenv gitignore\n"
        + (lib.concatStringsSep "\n" baseEntries)
        + "\n"
        + "### end\n"
        + (lib.optionalString (config.repoDevenv.gitignore.extraEntries != [ ]) (
          "\n" + lib.concatStringsSep "\n" config.repoDevenv.gitignore.extraEntries + "\n"
        ))
      );
    in
    {
      enterShell = "bash ${./enter-shell.sh} ${gitignoreFile}";
    };
}
