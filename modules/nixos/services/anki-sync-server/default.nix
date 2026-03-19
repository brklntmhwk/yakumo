# WIP
{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.yakumo.services.anki-sync-server;
  meta = config.yakumo.services.metadata.anki-sync-server;

  usersSubmodule = _: {
    options = {
      username = mkOption {
        type = types.str;
        description = "User name accepted by anki-sync-server.";
      };
      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          File containing the password accepted by anki-sync-server for
          the associated username.  Make sure to make readable only by
          root.
        '';
      };
    };
  };
in
{
  options.yakumo.services.anki-sync-server = {
    enable = mkEnableOption "anki-sync-server";
    # https://github.com/NixOS/nixpkgs/blob/ed142ab1b3a092c4d149245d0c4126a5d7ea00b0/nixos/modules/services/misc/anki-sync-server.nix
    users = mkOption {
      type = types.listOf (types.submodule usersSubmodule);
      description = "List of user-password pairs to provide to the sync server.";
      example = [
        {
          username = "foo";
          passwordFile = "path/to/password-file";
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    # https://docs.ankiweb.net/sync-server.html
    services.anki-sync-server = {
      inherit (meta)
        address # Default: '::1'
        port # Default: 27701
        users
        ;
      enable = true;
      baseDirectory = "%S/%N"; # Default: '%S/%N'
      openFirewall = false; # Default: false
    };

    yakumo.services.metadata.anki-sync-server.reverseProxy = {
      caddyIntegration.enable = true;
    };
  };
}
