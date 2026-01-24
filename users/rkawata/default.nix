{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) catAttrs;
  # theme = import ./themes/path-to-theme;
in
{
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
    media = {
      modules = [
        "music"
        "video/davinci-resolve"
      ];
    };
    compositors = {

    };
    apps = {

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

  yakumo.editors = {
    emacs = {
      enable = true;
      ametsuchi.enable = true;
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
      # filesystem.enable = true;
      github.enable = true;
    };
  };

  time.timeZone = "Asia/Tokyo";
}
