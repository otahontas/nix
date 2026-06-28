{ configFileValidator, pkgs, ... }:

{
  packages =
    (with pkgs; [
      emmylua-check
      emmylua-ls
      fish-lsp
      markdownlint-cli
      stylua
      taplo
      typescript
      typescript-language-server
      vscode-json-languageserver
      yaml-language-server
    ])
    ++ [
      configFileValidator
    ];
}
