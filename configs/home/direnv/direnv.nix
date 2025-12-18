{ ... }:
let
  envsDir = ../../../envs;

  # Get all directories in envs/
  envDirContents = builtins.readDir envsDir;
  envNames = builtins.filter (name: envDirContents.${name} == "directory") (
    builtins.attrNames envDirContents
  );

  # Create home.file entry for each env's .envrc
  mkEnvSymlink =
    name:
    let
      targetFile = envsDir + "/${name}/target";
      targetPath = builtins.replaceStrings [ "\n" "\r" ] [ "" "" ] (builtins.readFile targetFile);
    in
    {
      "${targetPath}/.envrc".source = envsDir + "/${name}/.envrc";
    };

  # Merge all env symlinks
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
