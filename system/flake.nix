{
  description = "system config, run with sudo";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      ...
    }:
    let
      username = "otahontas";
      hostname = "otabook";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./keyboard
          {
            system = {
              configurationRevision = self.rev or self.dirtyRev or null;
              stateVersion = 6;
              primaryUser = username;
              startup.chime = false;
              defaults = {
                loginwindow = {
                  GuestEnabled = false;
                  DisableConsoleAccess = true;
                  SHOWFULLNAME = false;
                };
                finder = {
                  QuitMenuItem = true;
                  AppleShowAllFiles = true;
                  AppleShowAllExtensions = true;
                  ShowPathbar = true;
                  ShowStatusBar = true;
                  FXEnableExtensionChangeWarning = false;
                  _FXSortFoldersFirst = true;
                  FXPreferredViewStyle = "Nlsv";
                };
                NSGlobalDomain = {
                  ApplePressAndHoldEnabled = false;
                  InitialKeyRepeat = 12;
                  KeyRepeat = 2;
                  NSDocumentSaveNewDocumentsToCloud = false;
                  NSAutomaticQuoteSubstitutionEnabled = false;
                  NSAutomaticDashSubstitutionEnabled = false;
                };
                dock = {
                  autohide = true;
                  "show-recents" = false;
                  "mru-spaces" = false;
                  tilesize = 20;
                  orientation = "bottom";
                };
                screencapture = {
                  location = "/Users/otahontas";
                  type = "png";
                  "disable-shadow" = true;
                  "show-thumbnail" = false;
                };
                trackpad = {
                  Clicking = true;
                  TrackpadThreeFingerDrag = true;
                };
              };
            };

            nix = {
              linux-builder.enable = true;
              optimise.automatic = true;
              gc = {
                automatic = true;
                interval = {
                  Weekday = 0;
                  Hour = 3;
                  Minute = 0;
                };
                options = "--delete-older-than 14d";
              };
              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                ];
                trusted-users = [ username ];
                substituters = [
                  "https://cache.nixos.org/"
                  "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
                accept-flake-config = false;
              };
            };
            security.pam.services.sudo_local.touchIdAuth = true;
            security.sudo.extraConfig = ''
              ${username} ALL=(root) NOPASSWD: \
                /run/current-system/sw/bin/mas install *
            '';
            programs.fish.enable = true;
            environment = {
              systemPackages = with nixpkgs.legacyPackages.aarch64-darwin; [
                home-manager
              ];
              shells = [ nixpkgs.legacyPackages.aarch64-darwin.fish ];
            };
            users = {
              knownUsers = [ username ];
              users.${username} = {
                uid = 501;
                home = "/Users/${username}";
                shell = nixpkgs.legacyPackages.aarch64-darwin.fish;
              };
            };
            networking = {
              hostName = hostname;
              localHostName = hostname;
              applicationFirewall = {
                enable = true;
                enableStealthMode = true;
                allowSigned = true;
                allowSignedApp = true;
              };
            };
          }
        ];
      };
    };
}
