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
  cfg = config.yakumo.services.forgejo;
  meta = config.yakumo.services.metadata.forgejo;
in
{
  options.yakumo.services.forgejo = {
    enable = mkEnableOption "forgejo";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.forgejo =
        let
          forgejoCfg = config.services.forgejo;
        in
        {
          enable = true;
          database =
            let
              pgMeta = config.yakumo.services.metadata.postgresql;
            in
            {
              inherit (pgMeta) port; # Use port 5432 for PostgreSQL DB.
              createDatabase = true; # Default: true
              type = "postgres"; # Default: 'sqlite3' (Options: 'mysql', 'postgres')
              name = "forgejo"; # Default: 'forgejo'
              user = "forgejo"; # Default: 'forgejo'
              host = pgMeta.address; # Default: '127.0.0.1'
              # Default: '${config.services.forgejo.stateDir}/data/forgejo.db'
              path = "${forgejoCfg.stateDir}/data/forgejo.db";
              passwordFile = config.sops.secrets."postgresql/passwd_file".path; # Default: null
              socket = "/run/mysqld/mysqld.sock"; # Default: null
            };
          dump = {
            enable = true; # Default: false
            # (Options: 'tar', 'tar.sz', 'tar.gz', 'tar.xz', 'tar.bz2', 'tar.br', 'tar.lz4', 'tar.zst')
            type = "zip"; # Default: 'zip'
            age = "4w"; # Default: '4w'
            backupDir = "${forgejoCfg.stateDir}/dump";
            # Specify the filename for the dump.
            # If null, Forgejo uses the default name.
            file = "forgejo-dump"; # Default: null
            # Run a Forgejo dump at this interval.
            interval = "04:31"; # Default: '04:31' (Options: 'hourly', etc.)
          };
          # LFS (Large File Storage)
          lfs = {
            enable = true; # Default: false
            contentDir = "${forgejoCfg.stateDir}/data/lfs";
          };
          group = "forgejo"; # Default: 'forgejo'
          user = "forgejo"; # Default: 'forgejo'
          customDir = "${forgejoCfg.stateDir}/custom"; # Default: '${config.services.forgejo.stateDir}/custom'
          stateDir = "/var/lib/forgejo"; # Default: '/var/lib/forgejo'
          repositoryRoot = "${forgejoCfg.stateDir}/repositories";
          useWizard = false; # Default: false
          # The value(s) given will be set for the `LoadCredential` systemd setting.
          secrets = { };
          settings = {
            log = {
              LEVEL = "Info"; # Default: 'Info' (Options: 'Trace', 'Debug', 'Warn', 'Error', 'Critical')
              ROOT_PATH = "${forgejoCfg.stateDir}/log";
            };
            server = {
              DISABLE_SSH = false; # Default: false
              DOMAIN = meta.domain; # Default: 'localhost'
              # Set this so it aligns with `PROTOCOL`.
              HTTP_ADDR = meta.address;
              HTTP_PORT = meta.port; # Default: '3000'
              PROTOCOL = "https"; # Default: 'http' (Options: 'https', 'fcgi', 'http+unix', 'fcgi+unix')
              ROOT_URL = "https://${meta.domain}/";
              SSH_PORT = 22; # Default: '2222'
              STATIC_ROOT_PATH = forgejoCfg.package.data;
            };
            session = {
              COOKIE_SECURE = false; # Default: false
            };
          };
        };

      yakumo =
        let
          rusticCfg = config.yakumo.services.rustic;
          yosugaCfg = config.yakumo.system.persistence.yosuga;
        in
        mkMerge [
          {
            services = {
              metadata.forgejo.reverseProxy = {
                caddyIntegration.enable = true;
              };
            };
          }
          (mkIf rusticCfg.enable {
            services.rustic.backups = {
              forgejo = {
                environmentFile = config.sops.secrets."forgejo/rustic_env_file".path;
                timerConfig = {
                  OnCalendar = "*-*-* 04:45:00"; # Run daily at 4:45 a.m.
                  Persistent = true;
                };
                settings = {
                  repository = {
                    repository = "s3:https://your-s3-endpoint/bucket/forgejo";
                  };
                  backup = {
                    snapshots = [
                      {
                        name = "forgejo";
                        sources = [
                          config.services.forgejo.dump.backupDir
                        ];
                      }
                    ];
                  };
                  forget = {
                    keep-daily = 7;
                    keep-weekly = 4;
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
                  inherit (forgejoCfg) group user;
                  path = forgejoCfg.stateDir;
                  mode = "0700";
                }
              ];
            };
          })
        ];

      sops.secrets = {
        "forgejo/rustic_env_file" = {
          sopsFile = rootPath + "/secrets/default.yaml";
          owner = "forgejo";
        };
      };
    }
  ]);
}
