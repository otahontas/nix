{
  pkgs,
  config,
  lib,
  ...
}:
let
  configsDir = ../.;
  toolDirs = builtins.readDir configsDir;
  collectNuFiles = lib.attrsets.mapAttrsToList (
    name: type:
    let
      nuFile = configsDir + "/${name}/${name}.nu";
    in
    if type == "directory" && name != "nushell" && builtins.pathExists nuFile then
      builtins.readFile nuFile
    else
      ""
  ) toolDirs;
  allIntegrations = lib.concatStrings collectNuFiles;
  coreConfig = builtins.readFile ./nushell.nu;
in
{
  home.packages = with pkgs; [
    (llm.withPlugins {
      llm-cmd = true;
    })
  ];
  catppuccin.nushell.enable = true;
  programs.nushell = {
    enable = true;
    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep)
        | prepend "${config.home.homeDirectory}/.local/bin"
        | prepend "/etc/profiles/per-user/${config.home.username}/bin"
        | prepend "/run/current-system/sw/bin"
        | prepend "/nix/var/nix/profiles/default/bin"
        | uniq
      )
      $env.VISUAL = "nvim"
      $env.EDITOR = "nvim"

      # Testcontainers support for Colima
      $env.DOCKER_HOST = $"unix://($env.HOME)/.colima/default/docker.sock"
      $env.TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock"
      $env.NODE_OPTIONS = "--dns-result-order=ipv4first"
    '';
    extraConfig = coreConfig + "\n" + allIntegrations;
  };
}
