{
  inputs.dev-env.url = "path:../../../lib/dev-env";
  outputs =
    { dev-env, ... }:
    dev-env.lib.mkEnv [
      "nodejs_20"
      "pnpm_8"
    ];
}
