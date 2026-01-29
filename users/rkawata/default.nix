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
  theme = import ./themes/modus-operandi-tinted;
in
{
  imports = [ ../common ];

  yakumo.user = {
    name = "rkawata";
    description = "Reiji Kawata";
    extraGroups = [
      "wheel"
    ];
    hashedPasswordFile = config.sops.secrets.login_password_rkawata.path;
    packages = builtins.attrValues {
      inherit (pkgs)
        ;
    };
  };

  yakumo.desktop = {
    enable = true;
    terminal = {
      wezterm = {
        enable = true;
        # settings = import ./configs/wezterm { };
      };
    };
    apps = {
      media = {
        modules = [
          "music"
          "video/davinci-resolve"
        ];
      };
    };
  };

  yakumo.shell = {
    zsh = {
      enable = true;
      defaultShell = true;
      defaultKeymap = "emacs";
      # setOptions = [];
      # shellAliases = {};
      # initExtraFirst = ''
      # '';
      # initExtraBeforeCompInit = ''
      # '';
      # initExtraLast = ''
      # '';
    };
    starship = {
      enable = true;
      settings = import ./configs/starship { inherit theme; };
    };
    zoxide = {
      enable = true;
    };
  };

  yakumo.ai = {
    agents = {
      claude-code = {
        enable = true;
      };
      gemini-cli = {
        enable = true;
      };
    };
    mcp = {
      enable = true;
      filesystem = {
        enable = true;
        paths = [
          "${config.yakumo.user.home}/projects"
        ];
      };
      github.enable = true;
    };
  };
}
