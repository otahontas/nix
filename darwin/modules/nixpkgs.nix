{ lib, inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.neovim-nightly-overlay.overlays.default
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];
}
