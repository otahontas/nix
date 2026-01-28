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
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    tonisives-tap = {
      url = "github:tonisives/homebrew-tap";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      tonisives-tap,
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
              defaults.loginwindow = {
                GuestEnabled = false;
                DisableConsoleAccess = true;
                SHOWFULLNAME = false;
              };
            };

            nix.settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              trusted-users = [ primaryUser ];
            };

            homebrew = {
              enable = true;
              user = adminUser;
              casks = [
                "blockblock"
                "firefox@developer-edition"
                "ghostty"
                "google-chrome"
                "lulu"
                "macwhisper"
                "orbstack"
                "orion"
                "pareto-security"
                "tonisives/tap/ovim"
              ];
              masApps = {
                "Logic Pro" = 634148309;
                "Lungo" = 1263070803;
                "MainStage" = 634159523;
                "Paprika Recipe Manager 3" = 1303222628;
                "Telegram" = 747648890;
                "Velja" = 1607635845;
                "WhatsApp Messenger" = 310633997;
                "WireGuard" = 1451685025;
                "iReal Pro" = 409035833;
                "reMarkable desktop" = 1276493162;
              };
            };

            programs.fish.enable = true;

            environment = {
              systemPackages = with inputs.nixpkgs.legacyPackages.aarch64-darwin; [
                home-manager
                just
                mas
              ];
              shells = [ nixpkgs.legacyPackages.aarch64-darwin.fish ];
            };

            users = {
              knownUsers = [ primaryUser ];
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
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = adminUser;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "tonisives/tap" = tonisives-tap;
              };
              mutableTaps = true;
            };
          }
        ];
      };
    };
}
