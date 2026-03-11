{
  config,
  lib,
  pkgs,
  flakeRoot,
  ...
}:

let
  inherit (builtins) attrValues;
  # inherit (lib) catAttrs;
  inherit (theme) cursorThemes fonts;
  theme = import ../../themes/modus-operandi-tinted pkgs;
in
{
  imports = [
    ../../../common # Common configs among users
  ];

  sops.secrets = {
    login_passwd_rkawata = {
      sopsFile = flakeRoot + "/secrets/default.yaml";
      neededForUsers = true;
    };
    gh_token_for_mcp = {
      sopsFile = flakeRoot + "/secrets/default.yaml";
    };
    # gh_token_for_mcp = {
    #   sopsFile = flakeRoot + "/users/rkawata/secrets/default.yaml";
    #   owner = config.yakumo.user.name;
    # };
    git_signing_key = {
      sopsFile = flakeRoot + "/users/rkawata/secrets/default.yaml";
      owner = "rkawata";
      mode = "0400";
    };
  };

  yakumo = {
    user = {
      name = "rkawata";
      description = "Reiji Kawata";
      uid = 1001;
      hashedPasswordFile = config.sops.secrets.login_passwd_rkawata.path;
      # packages = catAttrs "package" (attrValues cursorThemes);
    };
    shell = {
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
    ai = {
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
          paths = [ "${config.yakumo.user.home}/projects" ];
        };
        github.enable = true;
      };
    };
  };
}
