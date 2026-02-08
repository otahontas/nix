# How to use:
# - Setup admin account in setup assistant
# - Enable firevault
# - Install nix (e.g. https://lix.systems/install/)
# - Install software tools
# - Apply this setup
# - Login to day-to-day user
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
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      ...
    }:
    let
      adminUser = "otahontas-admin";
      primaryUser = "otahontas";
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
              inherit primaryUser;
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

            nix.linux-builder.enable = true;

            nix.settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              trusted-users = [ primaryUser ];
            };

            security.pam.services.sudo_local.touchIdAuth = true;
            security.sudo.extraConfig = ''
              ${primaryUser} ALL=(root) NOPASSWD: \
                /run/current-system/sw/bin/mas version, \
                /run/current-system/sw/bin/mas install *, \
                /run/current-system/sw/bin/mas get *, \
                /run/current-system/sw/bin/mas uninstall *, \
                /run/current-system/sw/bin/mas update *, \
                /run/current-system/sw/bin/mas upgrade *, \
                /run/current-system/sw/bin/mas lucky *
            '';

            programs.fish.enable = true;

            environment = {
              systemPackages = with inputs.nixpkgs.legacyPackages.aarch64-darwin; [
                home-manager
                mas
              ];
              shells = [ nixpkgs.legacyPackages.aarch64-darwin.fish ];
            };

            users = {
              knownUsers = [
                adminUser
                primaryUser
              ];
              users.${adminUser} = {
                uid = 501;
                home = "/Users/${adminUser}";
                shell = nixpkgs.legacyPackages.aarch64-darwin.fish;
              };
              users.${primaryUser} = {
                uid = 502; # 501 is for the first user (admin)
                home = "/Users/${primaryUser}";
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
