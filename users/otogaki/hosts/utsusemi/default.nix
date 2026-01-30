{
  config,
  lib,
  ...
}:

let
  inherit (theme) fonts;
  theme = import ../../themes/modus-vivendi-tinted;
in
{
  imports = [
    ../common # Common configs among user's hosts
  ];

  yakumo.system = {
    i18n = {
      inputMethod = {
        enable = true;
        fcitx5 = {
          enable = true;
          extraAddons = [ ];
          quickPhrase = { };
        };
      };
    };
  };

  yakumo.desktop = {
    terminal = {
      wezterm = {
        enable = true;
        settings = import ../../configs/wezterm { inherit theme; };
      };
    };
    apps = {
      browsers = {
        
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
