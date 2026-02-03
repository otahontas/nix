{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi.piception;

  piceptionBundle = pkgs.runCommand "pi-piception-extension" { } ''
    mkdir -p $out
    cp ${./extensions/piception/index.ts} $out/piception.ts
    cp ${./extensions/piception/extraction-prompt.md} $out/extraction-prompt.md
    cp ${./extensions/piception/skill-template.md} $out/skill-template.md
  '';
in
{
  options.programs.pi.piception = {
    enable = lib.mkEnableOption "Piception extension for pi coding agent";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".pi/agent/extensions/piception.ts".source = "${piceptionBundle}/piception.ts";
      ".pi/agent/extensions/extraction-prompt.md".source = "${piceptionBundle}/extraction-prompt.md";
      ".pi/agent/extensions/skill-template.md".source = "${piceptionBundle}/skill-template.md";
    };
  };
}
