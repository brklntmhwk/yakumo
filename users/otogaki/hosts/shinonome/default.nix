{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) catAttrs recursiveUpdate;
  inherit (theme) cursorThemes fonts loginThemes;
  inherit (murakumo.configs) hexToRgba;
  theme = import ../../themes/modus-vivendi-tinted pkgs;
  systemWideBinPath = "/run/current-system/sw/bin";
in
{
  imports = [
    ../common # Common configs among user's hosts.
  ];

  yakumo.system = {
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

  yakumo.desktop = {
    enable = true;
    compositors = {
      niri = {
        enable = true;
        xwayland.enable = true;
        settings = recursiveUpdate (import ../../configs/niri { inherit theme; }) (
          import ../../configs/niri/config-shinonome.nix
        );
        loginSettings = import ../../configs/niri/login-shinonome.nix;
        greeter.regreet = {
          enable = true;
        } // (import ../../configs/regreet { inherit theme; });
        # greeter.tuigreet = {
        #   enable = true;
        #   themeArgs = import ../../configs/tuigreet/theme.nix { inherit theme; };
        # };
      };
    };
    daemons = {
      awww = {
        enable = true;
      };
      mako = {
        enable = true;
        settings = import ../../configs/mako { inherit theme; };
      };
      swayidle = {
        enable = true;
        settings = import ../../configs/swayidle { inherit systemWideBinPath; };
      };
    };
    lockers = {
      swaylock = {
        enable = true;
        settings = import ../../configs/swaylock { inherit theme; };
      };
    };
    terminal = {
      wezterm = {
        enable = true;
        settings = import ../../configs/wezterm { inherit lib theme; };
      };
    };
    ui = {
      waybar = {
        enable = true;
        settings = import ../../configs/waybar/niri-config.nix;
        style = import ../../configs/waybar/style.nix { inherit theme hexToRgba; };
      };
      wofi = {
        enable = true;
        settings = import ../../configs/wofi;
        style = import ../../configs/wofi/style.nix { inherit theme; };
      };
    };
    apps = {
      browsers = {
        brave = {
          enable = true;
        };
        nyxt = {
          enable = true;
          config = ../../configs/nyxt/init.lisp;
        };
      };
      media = {
        modules = [
          "music"
          "video"
        ];
      };
      misc = {
        thunar = {
          enable = true;
        };
      };
    };
  };

  yakumo.editors = {
    emacs = {
      enable = true;
      ametsuchi.enable = true;
    };
  };

  yakumo.programs = {
    wthrr = {
      enable = true;
      settings = import ../../configs/wthrr;
    };
  };

  yakumo.services = {
    xremap = {
      enable = true;
      userName = config.yakumo.user.name;
      settings = import ../../configs/xremap;
    };
  };

  programs.yazi = {
    enable = true;
    settings = import ../../configs/yazi { inherit theme; };
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
