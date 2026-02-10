{ config, lib, pkgs, ... }:

let
  inherit (builtins) attrValues;
  # inherit (lib) catAttrs;
  inherit (theme) cursorThemes fonts;
  theme = import ../../themes/modus-operandi-tinted pkgs;
in {
  imports = [
    ../../../common # Common configs among users
  ];

  yakumo.user = {
    name = "rkawata";
    description = "Reiji Kawata";
    uid = 1001;
    hashedPasswordFile = config.sops.secrets.login_password_rkawata.path;
    # packages = catAttrs "package" (attrValues cursorThemes);
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
    zoxide = { enable = true; };
  };

  yakumo.ai = {
    agents = {
      claude-code = { enable = true; };
      gemini-cli = { enable = true; };
    };
    mcp = {
      enable = true;
      filesystem = {
        enable = true;
        paths = [ "${config.yakumo.user.home}/projects" ];
      };
      github.enable = true;
    };
  };
}
