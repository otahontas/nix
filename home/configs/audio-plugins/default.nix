{ pkgs, ... }:
{
  home.packages = [
    # hash not provided by brew cask, override with correct hash
    (pkgs.brewCasks.waves-central.overrideAttrs (oldAttrs: {
      src = pkgs.fetchurl {
        url = builtins.head oldAttrs.src.urls;
        hash = "sha256-ULDktkmYhPkZuncx7J4t+0+e+HTL3BKYuJOxo+gfDfU=";
      };
    }))
    (pkgs.brewCasks.native-access.overrideAttrs (oldAttrs: {
      src = pkgs.fetchurl {
        url = builtins.head oldAttrs.src.urls;
        hash = "sha256-/J2NmTaAwUdXXQ3gxFeLflaPYGWk6k6TPhCNkY6WtdI=";
      };
    }))
  ];
}
