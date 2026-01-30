{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) catAttrs;
  inherit (theme) cursorThemes fonts loginThemes;
  theme = import ../../themes/modus-vivendi-tinted;
in
{
  imports = [
    ../common # Common configs among user's hosts
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
        xwayland = true;
        settings = import ../../configs/niri { inherit theme; };
        regreet = {
          theme = {
            name = loginThemes.adwaita.name;
            package = loginThemes.adwaita.package;
          };
          cursorTheme = {
            name = cursorThemes.adwaita.name;
            package = cursorThemes.adwaita.package;
          };
          font = {
            name = fonts.moralerspaceHw.name;
            package = fonts.moralerspaceHw.package;
            size = 16;
          };
        };
      };
    };
    daemons = {
      mako = {
        enable = true;
        settings = import ../../configs/mako { inherit theme; };
      };
      swayidle = {
        enable = true;
        settings = import ../../configs/swayidle { };
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
        settings = import ../../configs/wezterm { inherit theme; };
      };
    };
    ui = {
      waybar = {
        enable = true;
        settings = import ../../configs/waybar { };
        style = import ../../configs/waybar/style.nix { inherit theme; };
      };
      wofi = {
        enable = true;
        settings = import ../../configs/wofi { };
        style = import ../../configs/wofi/style.nix { inherit theme; };
      };
    };
    apps = {
      browsers = {
        nyxt = {
          enable = true;
          config = import ../../configs/nyxt/init.lisp { };
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
      settings = import ../../configs/wthrr { };
    };
  };

  yakumo.services = {
    xremap = {
      enable = true;
      userName = config.yakumo.user.name;
      serviceMode = "user";
      config = import ../../configs/xremap { };
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
