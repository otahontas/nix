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
    "server:update-keys" = {
      exec = ''
        echo "Fetching public key from pass..."
        if ! OTAPI_PUBKEY="$(pass otapi/public_key)"; then
           echo "Error: Failed to fetch key from pass. Make sure 'otapi/public_key' exists."
           exit 1
        fi

        echo "[ \"$OTAPI_PUBKEY\" ]" > ssh-keys.nix

        # Register the file with git so pure flakes can see it,
        # but force it because it is in .gitignore
        git add -N -f ssh-keys.nix || true

        echo "Successfully updated ssh-keys.nix"
      '';
    };
  };
}
