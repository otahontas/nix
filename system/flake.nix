# How to use:
# - Enable firevault
# - Install nix (e.g. https://lix.systems/install/)
# - Install software tools
# - Apply this setup
# - Apply home manager stuff
# - Apply stuff from https://github.com/drduh/macOS-Security-and-Privacy-Guide
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
                  "https://devenv.cachix.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
                ];

                accept-flake-config = false;
              };
            };

            security.pam.services.sudo_local.touchIdAuth = true;
            security.sudo.extraConfig = ''
              ${username} ALL=(root) NOPASSWD: \
                /run/current-system/sw/bin/mas install *
            '';

            programs.fish = {
              enable = true;
              interactiveShellInit = ''
                function system-apply
                  set -l root "$DEVENV_ROOT"
                  if test -z "$root"
                    set root (command git rev-parse --show-toplevel 2>/dev/null)
                  end
                  if test -z "$root"
                    echo "system-apply: run inside repo or devenv shell"
                    return 1
                  end
                  sudo darwin-rebuild switch --flake "$root/system#${hostname}"
                end
              '';
            };

            environment = {
              systemPackages = with nixpkgs.legacyPackages.aarch64-darwin; [
                home-manager
                mas
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
