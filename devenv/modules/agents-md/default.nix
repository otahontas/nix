{
  lib,
  pkgs,
  config,
  ...
}:
let
  baseContent = builtins.readFile ./BASE_AGENTS.md;

  agentsMdContent =
    baseContent
    + (lib.optionalString (config.repoDevenv.agents-md.extraEntries != [ ]) (
      "\n\n" + (lib.concatStringsSep "\n" config.repoDevenv.agents-md.extraEntries) + "\n"
    ));
in
{
  options.repoDevenv.agents-md.extraEntries = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config = {
    enterShell = "bash ${./enter-shell.sh} ${pkgs.writeText "agents-md" agentsMdContent}";
  };
}
