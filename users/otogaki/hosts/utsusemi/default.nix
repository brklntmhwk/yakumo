{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (theme) fonts;
  theme = import ../../themes/modus-vivendi-tinted pkgs;
in
{
  imports = [
    ../common # Common configs among user's hosts.
  ];

  yakumo = {
    system = {
      i18n = {
        inputMethod = {
          fcitx5 = {
            enable = true;
            extraAddons = [ ];
            quickPhrase = { };
          };
        };
      };
    };
    desktop = {
      enable = true;
      compositors = {
        niri = {
          enable = true;
          xwayland.enable = true;
          settings = recursiveUpdate (import ../../configs/niri { inherit theme; }) (
            import ../../configs/niri/config-tsutsuyami.nix
          );
          loginSettings = import ../../configs/niri/login-tsutsuyami.nix;
          greeter.regreet = {
            enable = true;
          }
          // (import ../../configs/regreet { inherit theme; });
        };
      };
      lockers = {
        hyprlock = {
          enable = true;
          settings = import ../../configs/hyprlock { inherit theme; };
        };
      };
      daemons = {
        swayidle = {
          enable = true;
          settings = import ../../configs/swayidle { inherit config lib; };
        };
      };
      terminal = {
        wezterm = {
          enable = true;
          settings = import ../../configs/wezterm { inherit lib theme; };
        };
      };
    };
    tools = {
      editors = {
        emacs = {
          enable = true;
          ametsuchi.enable = true;
        };
      };
      misc = {
        wthrr = {
          enable = true;
          settings = import ../../configs/wthrr;
        };
      };
    };
  };

  fonts = {
    # 'fonts.packages' are configured in the common file.
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [ fonts.notoCjkSerif.name ];
        sansSerif = [ fonts.notoCjkSans.name ];
        monospace = [ fonts.hackgenNf.name ];
        emoji = [ fonts.notoEmoji.name ];
      };
    };
  };
}
