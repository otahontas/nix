{
  lib,
  pkgs,
  config,
  ...
}:
let
  baseServers = (builtins.fromJSON (builtins.readFile ./mcp.json)).mcpServers;
  merged = baseServers // config.repoDevenv.ai.mcp.extraServers;
  mcpConfig = pkgs.writeText "mcp.json" (builtins.toJSON { mcpServers = merged; });
  postEditHook = pkgs.writeText "post-edit-hook.ts" (builtins.readFile ./post-edit-hook.ts);
in
{
  options.repoDevenv.ai.mcp.extraServers = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = { };
  };

  config = {
    claude.code.enable = lib.mkForce false;

    enterShell = "bash ${./enter-shell.sh} ${mcpConfig} ${postEditHook}";
  };
}
