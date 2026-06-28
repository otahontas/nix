{ piExtensionsTypecheck, ... }:

{
  tasks = {
    "home:apply" = {
      description = "Apply home-manager configuration from ./home flake";
      exec = "home-manager switch --flake ./home";
    };
    "system:apply" = {
      description = "Apply system from ./system flake";
      exec = "sudo darwin-rebuild switch --flake ./system";
    };
    "nix:format" = {
      description = "Run treefmt formatters";
      exec = "treefmt -v";
    };
    "nix:update" = {
      description = "Update flakes, devenv, home-manager, and pi extensions";
      exec = ''
        nix flake update --flake ./home
        nix flake update --flake ./system
        devenv update
        devenv tasks run home:apply && pi update --extensions
      '';
    };
    "pi-extensions:typecheck" = {
      description = "Typecheck local Pi TypeScript extensions";
      exec = "${piExtensionsTypecheck}";
    };
  };
}
