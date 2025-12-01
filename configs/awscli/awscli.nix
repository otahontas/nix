{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    awscli2
  ];

  # Generate AWS config from pass at activation time
  home.activation.generateAwsConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.nushell}/bin/nu ${./generate-aws-config.nu} ${pkgs.pass}/bin/pass
  '';
}
