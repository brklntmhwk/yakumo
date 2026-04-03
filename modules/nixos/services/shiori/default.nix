# WIP
{
  config,
  lib,
  murakumo,
  rootPath,
  rootMeta,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.shiori;
  meta = config.yakumo.services.metadata.shiori;
in
{
  options.yakumo.services.shiori = {
    enable = mkEnableOption "shiori";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions =
        let
          inherit (murakumo.assertions) assertServiceUp;
        in
        [
          (assertServiceUp "paperless-ngx" rootMeta.allServices)
        ];

      services = {
        shiori = {
          inherit (meta)
            # If empty, Shiori listens on all interfaces.
            address # Default: ''
            port # Default: 8080
            ;
          enable = true;
          environmentFile = config.sops.secrets."shiori/env_file".path; # Default: null
          # Shiori can use MySQL or PostgreSQL.
          # This will be the value of `SHIORI_DATABASE_URL`.
          databaseUrl = "postgres:///shiori?host=/run/postgresql"; # Default: null
          webRoot = "/"; # Default: '/'
        };
        postgresql = {
          ensureDatabases = [ "shiori" ];
          ensureUsers = [
            {
              name = "shiori";
              ensureDBOwnership = true;
            }
          ];
        };
      };

      yakumo =
        let
          inherit (lib) elem;
          dataDir = "/var/lib/shiori";
          privateDatadir = "/var/lib/private/shiori";
          yosugaCfg = config.yakumo.system.persistence.yosuga;
        in
        mkMerge [
          {
            services.metadata.shiori.reverseProxy = {
              caddyIntegration.enable = true;
            };
          }
          (mkIf (elem "rustic" rootMeta.allServices) {
            services.rustic.backups = {
              shiori = {
                environmentFile = config.sops.secrets."shiori/rustic_env_file".path;
                timerConfig = {
                  OnCalendar = "*-*-* 05:00:00"; # Run daily at 5 a.m.
                  Persistent = true;
                };
                settings = {
                  repository = {
                    repository = "s3:https://your-s3-endpoint/bucket/shiori";
                  };
                  backup = {
                    snapshots = [
                      {
                        name = "shiori";
                        sources = [ privateDatadir ];
                      }
                    ];
                  };
                  forget = {
                    keep-hourly = 24;
                    keep-daily = 14;
                    keep-weekly = 8;
                    keep-monthly = 12;
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
                  path = privateDatadir;
                  mode = "0700";
                }
              ];
            };
          })
        ];

      sops.secrets = {
        "shiori/env_file" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
        "shiori/rustic_env_file" = {
          sopsFile = rootPath + "/secrets/default.yaml";
        };
      };
    }
  ]);
}
