{ ... }:
let
  envsDir = ../../../envs;

  envDirContents = builtins.readDir envsDir;
  envNames = builtins.filter (name: envDirContents.${name} == "directory") (
    builtins.attrNames envDirContents
  );

  mkEnvSymlink =
    name:
    let
      targetFile = envsDir + "/${name}/target";
      targetPath = builtins.replaceStrings [ "\n" "\r" ] [ "" "" ] (builtins.readFile targetFile);
      # Use .envrc.in to avoid direnv triggering in source tree
      envrcFile = envsDir + "/${name}/.envrc.in";
    in
    {
      "${targetPath}/.envrc".source = envrcFile;
    };

  envSymlinks = builtins.foldl' (acc: name: acc // (mkEnvSymlink name)) { } envNames;
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableNushellIntegration = true;
  };
  home.file = envSymlinks;
}
