# WIP
{
  config,
  lib,
  pkgs,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.immich;
  meta = config.yakumo.services.metadata.immich;
in
{
  options.yakumo.services.immich = {
    enable = mkEnableOption "immich";
  };

  config = mkIf cfg.enable (
    let
      inherit (meta) address domain port;
      backupDir = "/var/backup/immich";
      immichCfg = config.services.immich;
      rusticCfg = config.yakumo.services.rustic;
    in
    mkMerge [
      {
        services.immich = {
          inherit port; # Default: 2283
          enable = true;
          group = "immich"; # Default: 'immich'
          user = "immich"; # Default: 'immich'
          host = address; # Default: 'localhost'
          secretsFile = config.sops.secrets."immich/secrets_file".path;
          openFirewall = false; # Default: false
          # Specify device paths to hardware acceleration devices that
          # immich should have access to.
          # This is helpful when transcoding media files.
          # `[ ]` (Empty list) will disallow all devices using `PrivateDevices`.
          # Give access to all devices if set to null.
          accelerationDevices = [ ];
          # For the valid env variables, see:
          # https://docs.immich.app/install/environment-variables/
          environment = {
            IMMICH_LOG_LEVEL = "verbose";
          };
          # Specify the directory used to store media files.
          # Ensure to create it manually and give the immich user the R&W permissions
          # if not using the default directory.
          mediaLocation = "/var/lib/immich";
          # Enabling this adds "postgresql.target" to some options of
          # every Systemd service configured behind the scenes.
          database =
            let
              pgMeta = config.yakumo.services.metadata.postgresql;
            in
            {
              inherit (pgMeta) port; # Default: 5432
              enable = true; # Default: true
              createDB = true; # Default: true
              name = "immich"; # Default: 'immich'
              user = "immich"; # Default: 'immich'
              # Specify the hostname or address of the PostgreSQL server.
              host = "/run/postgresql"; # Default: '/run/postgresql'
              # Set this to false if you use VectorChord instead.
              enableVectors = false;
              enableVectorChord = true; # Default: true
            };
          # Enabling this creates a Systemd service for the Immich's
          # machine learning features.
          machine-learning = {
            enable = true; # Default: true
            # For the valid env variables, see:
            # https://docs.immich.app/install/environment-variables/
            environment = { };
          };
          redis = {
            enable = true; # Default: true
            host = config.services.redis.servers.immich.unixSocket;
            port = 0; # Default: 0
          };
          settings = {
            backup.database = {
              # Disable the built-in backup feature in favor of our Rustic backup
              # support.
              enabled = false;
            };
            job = {
              backgroundTask.concurrency = 5;
              faceDetection.concurrency = 2;
              library.concurrency = 5;
              metadataExtraction.concurrency = 5;
              migration.concurrency = 5;
              notifications.concurrency = 5;
              search.concurrency = 5;
              sidecar.concurrency = 5;
              smartSearch.concurrency = 2;
              thumbnailGeneration.concurrency = 3;
              videoConversion.concurrency = 1;
            };
            logging = {
              enabled = true;
              level = "log";
            };
            machineLearning = {
              enabled = true;
              clip = {
                enabled = true;
                modelName = "ViT-B-32__openai";
              };
              duplicateDetection = {
                enabled = true;
                maxDistance = 0.01;
              };
            };
            newVersionCheck.enabled = false; # Default: false
            # Domain for publicly shared links, including http(s)://.
            server = {
              externalDomain = "https://${domain}"; # Default: ''
              loginPageMessage = "A trip down memory lane.";
            };
          };
        };

        yakumo =
          let
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata = {
                immich.reverseProxy = {
                  caddyIntegration.enable = true;
                };
              };
            }
            (mkIf yosugaCfg.enable {
              system.persistence.yosuga = {
                directories = [
                  {
                    inherit (immichCfg) group user;
                    path = immichCfg.mediaLocation;
                    mode = "0750";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          "immich/secrets_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "immich";
          };
          "immich/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "immich";
          };
        };
      }
      (mkIf rusticCfg.enable {
        yakumo.services.rustic.backups = {
          immich = {
            environmentFile = config.sops.secrets."immich/rustic_env_file".path;
            timerConfig = {
              OnCalendar = "*-*-* 04:00:00"; # Run daily at 4 a.m.
              Persistent = true;
            };
            settings = {
              repository = {
                repository = "s3:https://your-s3-endpoint/bucket/immich";
              };
              backup = {
                snapshots = [
                  {
                    name = "immich";
                    sources = [
                      immichCfg.mediaLocation
                      backupDir
                    ];
                  }
                ];
              };
              forget = {
                keep-daily = 7;
                keep-weekly = 4;
                keep-monthly = 3;
                prune = true;
              };
            };
          };
        };

        # Handle the Immich PostgreSQL DB dump before Rustic runs.
        systemd.services."rustic-backups-immich" = {
          preStart = ''
            mkdir -p ${backupDir}
            ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump -Fc immich > ${backupDir}/immich.dump
          '';
        };
      })
    ]
  );
}
