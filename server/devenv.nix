_: {
  tasks = {
    "server:deploy" = {
      exec = "nix run github:serokell/deploy-rs -- .#otapi";
    };
    "server:build" = {
      exec = "nix build .#nixosConfigurations.otapi.config.system.build.toplevel";
    };
    "server:deploy-rebuild" = {
      exec = "nixos-rebuild switch --flake .#otapi --target-host otahontas@otapi --use-remote-sudo";
    };
    "server:ssh" = {
      exec = "ssh otahontas@otapi";
    };
    "server:check" = {
      exec = "nix flake check";
    };
  };
}
