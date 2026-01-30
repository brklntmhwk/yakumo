{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
in
{
  imports = [
    ../../../common # Common configs among users
  ];

  yakumo.user = {
    name = "rkawata";
    description = "Reiji Kawata";
    extraGroups = [
      "wheel"
    ];
    hashedPasswordFile = config.sops.secrets.login_password_rkawata.path;
    packages = attrValues {
      inherit (pkgs)
        ;
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
