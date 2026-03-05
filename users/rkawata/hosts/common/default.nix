{
  config,
  lib,
  pkgs,
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
    # TODO: Move this to under rkawata's secrets file.
    login_password_rkawata.sopsFile = ../../../../secrets/default.yaml;
    gh_token_for_mcp.sopsFile = ../../secrets/default.yaml;
    git_signing_key = ../../secrets/default.yaml;
  };

  yakumo = {
    user = {
      name = "rkawata";
      description = "Reiji Kawata";
      uid = 1001;
      hashedPasswordFile = config.sops.secrets.login_password_rkawata.path;
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
