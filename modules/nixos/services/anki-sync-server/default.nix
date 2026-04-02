# WIP
{
  config,
  lib,
  rootPath,
  yakumoMeta,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
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
          the associated username. Make sure to make it readable only by
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
      # This will be bound to `SYNC_BASE`.
      # e.g., '/f/foo/' for User 'foo'
      baseDirectory = "%S/%N"; # Default: '%S/%N'
      openFirewall = false; # Default: false
    };

    yakumo =
      let
        inherit (lib) elem;
        dataDir = "/var/lib/private/anki-sync-server";
        yosugaCfg = config.yakumo.system.persistence.yosuga;
      in
      mkMerge [
        {
          services.metadata.anki-sync-server.reverseProxy = {
            caddyIntegration.enable = true;
          };
        }
        (mkIf (elem "rustic" yakumoMeta.allServices) {
          services.rustic.backups = {
            anki-sync-server = {
              environmentFile = config.sops.secrets."anki-sync-server/rustic_env_file".path;
              timerConfig = {
                OnCalendar = "*-*-* 04:30:00"; # Run daily at 4:30 a.m.
                Persistent = true;
              };
              settings = {
                repository = {
                  repository = "s3:https://your-s3-endpoint/bucket/mealie";
                };
                backup = {
                  snapshots = [
                    {
                      name = "anki-sync-server";
                      sources = [ dataDir ];
                    }
                  ];
                };
                forget = {
                  keep-daily = 7;
                  keep-weekly = 4;
                  keep-monthly = 6;
                  prune = true;
                };
              };
            };
          };
        })
        (mkIf yosugaCfg.enable {
          system.persistence.yosuga = {
            directories = [
              # Specify the private data directory as the upstream module enables
              # `serviceConfig.DynamicUser` for the Mealie systemd service.
              {
                path = dataDir;
                mode = "0700";
              }
            ];
          };
        })
      ];

    sops.secrets = {
      "anki-sync-server/rustic_env_file" = {
        sopsFile = rootPath + "/secrets/default.yaml";
      };
    };
  };
}
