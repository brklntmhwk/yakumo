# WIP
{
  config,
  lib,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.paperless-ngx;
  meta = config.yakumo.services.metadata.paperless-ngx;
in
{
  options.yakumo.services.paperless-ngx = {
    enable = mkEnableOption "paperless-ngx";
  };

  config = mkIf cfg.enable (
    let
      paperlessCfg = config.services.paperless;
    in
    mkMerge [
      {
        services.paperless = {
          inherit (meta)
            address # Default: '127.0.0.1'
            domain # Default: null
            port # Default: 28981
            ;
          enable = true;
          user = "paperless"; # Default: 'paperless'
          environmentFile = config.sops.secrets."paperless/env_file".path; # Default: null
          passwordFile = config.sops.secrets."paperless/passwd_file".path;
          consumptionDir = "${paperlessCfg.dataDir}/consume";
          # Allow all users can write to the consumption directory if set to true.
          consumptionDirIsPublic = false; # Default: false
          dataDir = "/var/lib/paperless"; # Default: '/var/lib/paperless'
          # This is where actual PDF files are stored.
          mediaDir = "${paperlessCfg.dataDir}/media";
          # Configure local PostgreSQL DB server.
          database.createLocally = true; # Default: false
          # TODO: Consider implementing and using a systemd backup service & Rustic for backups instead.
          # Configure the document exporter.
          # For more details, see:
          # https://docs.paperless-ngx.com/administration/#exporter
          exporter = {
            enable = true; # Default: false
            directory = "${paperlessCfg.dataDir}/export";
            # Schedule when to run the exporter.
            onCalendar = "02:00:00";
            settings = {
              compare-checksums = true;
              delete = true;
              no-color = true;
              no-progress-bar = true;
            };
          };
          # Enable a workaround for document classifier timeouts.
          # This sets `OMP_NUM_THREADS` to 1.
          # For the detail, see: https://github.com/NixOS/nixpkgs/issues/240591
          openMPThreadingWorkaround = true; # Default: true
        };

        yakumo =
          let
            rusticCfg = config.yakumo.services.rustic;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata = {
                paperless-ngx.reverseProxy = {
                  caddyIntegration.enable = true;
                };
              };
            }
            (mkIf rusticCfg.enable {
              services.rustic.backups = {
                paperless = {
                  environmentFile = config.sops.secrets."paperless/rustic_env_file".path;
                  timerConfig = {
                    OnCalendar = "*-*-* 02:45:00"; # Run daily at 2:45 a.m.
                    Persistent = true;
                  };
                  settings = {
                    repository = {
                      repository = "s3:https://your-s3-endpoint/bucket/paperless";
                    };
                    backup = {
                      snapshots = [
                        {
                          name = "paperless";
                          sources = [
                            paperlessCfg.exporter.directory
                          ];
                        }
                      ];
                    };
                    forget = {
                      keep-daily = 7;
                      keep-weekly = 4;
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
                  {
                    path = paperlessCfg.dataDir;
                    user = "paperless";
                    group = "paperless";
                    mode = "0750";
                  }
                  {
                    path = paperlessCfg.exporter.directory;
                    user = "paperless";
                    group = "paperless";
                    mode = "0750";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          "paperless/env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "paperless";
          };
          "paperless/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "paperless";
          };
          "paperless/passwd_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "paperless";
          };
        };
      }
    ]
  );
}
