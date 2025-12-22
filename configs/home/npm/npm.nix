{
  home.file.".npmrc".source = ./.npmrc;

  programs.nushell.environmentVariables = {
    NODE_OPTIONS = "--dns-result-order=ipv4first";
  };
}
