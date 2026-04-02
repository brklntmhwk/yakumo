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
    ;
  cfg = config.yakumo.services.postgresql;
  meta = config.yakumo.services.metadata.postgresql;
in
{
  options.yakumo.services.postgresql = {
    enable = mkEnableOption "postgresql";
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = {
        enable = true;
        enableJIT = false; # Default: false
        enableTCPIP = false; # Default: false
        # Define how users authenticate themselves to the server.
        # By default:
        # - peer based authentication will be used for users connecting via the Unix socket.
        # - md5 password authentication will be used for users connecting via TCP.
        # Any added rules will be inserted above the default rules.
        # Use `lib.mkForce` if you want to replace the default rules entirely.
        # For the valid config format, see:
        # https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
        authentication = ""; # Default: ''
        # Check the config file syntactically at compile time.
        checkConfig = true; # Default: true
        dataDir = "/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";
        # NOTE: Configure these options in each module that uses Postgresql DB.
        # ensureDatabases = [
        #   # Add PostgreSQL DB for each service here to ensure their presence.
        # ];
        # ensureUsers = [
        #   # Add PostgreSQL DB users for each service here to ensure their presence.
        # ];
        # List of PostgreSQL extensions to install.
        extensions = [ ];
        # Define the mapping from system users to DB users.
        # Each line should look like:
        # 'map-name-0 system-username-0 database-username-0'
        identMap = ""; # Default: ''
        # Pass additional args to `initdb` during data directory initialization.
        initdbArgs = [ ]; # Default: [ ]
        # Specify a file that contains SQL statements to execute on first startup.
        initialScript = null; # Default: null
        # Configure the syscall filter for `postgresql.service`.
        # The ordering matters.
        systemCallFilter = {
          "@system-service" = true;
          "~@privileged" = true;
          "~@resources" = true;
          # This also accepts the following format with explicit priority:
          # "foobar" = {
          #   enable = true;
          #   priority = 100;
          # };
        };
        settings = {
          inherit (meta) port; # Default: 5432
          log_line_prefix = "[%p] "; # Default: '[%p] '
          shared_preload_libraries = null; # Default: null
        };
      };

      postgresqlBackup = {
        enable = true;
        compression = "gzip"; # Default: 'gzip' (Options: 'none', 'zstd')
        # Specify the compression level.
        # gzip accepts 1 to 9, whereas zstd accepts 1 to 19.
        compressionLevel = 6; # Default: 6
        location = "/var/backup/postgresql"; # Default: '/var/backup/postgresql'
        # Dump the database daily at 2:30 a.m.
        startAt = "*-*-* 02:30:00"; # Default: '*-*-* 01:15:00'
        # Leaving this empty means backing up all.
        databases = [ ]; # Default: [ ]
        # Specify the command line options for pg_dump.
        pgdumpOptions = "-C"; # Default: '-C'
      };
    };

    yakumo =
      let
        inherit (lib) elem;
        yosugaCfg = config.yakumo.system.persistence.yosuga;
        pgBackupCfg = config.services.postgresqlBackup;
      in
      mkMerge [
        (mkIf (elem "rustic" yakumoMeta.allServices) {
          services.rustic.backups = {
            postgresql = {
              environmentFile = config.sops.secrets."postgresql/rustic_env_file".path;
              timerConfig = {
                OnCalendar = "*-*-* 03:15:00"; # Run daily at 3:15 a.m.
                Persistent = true;
              };
              settings = {
                repository = {
                  repository = "s3:https://your-s3-endpoint/bucket/postgresql";
                };
                backup = {
                  snapshots = [
                    {
                      name = "postgresql";
                      sources = [ pgBackupCfg.location ];
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
        })
        (mkIf yosugaCfg.enable {
          system.persistence.yosuga = {
            directories = [
              {
                # Default data directory for NixOS Postgres.
                path = config.services.postgresql.dataDir;
                user = "postgres";
                group = "postgres";
                mode = "0700";
              }
              # If setting up local pg_dump staging for Rustic, persist that too.
              {
                path = pgBackupCfg.location;
                user = "postgres";
                group = "postgres";
                mode = "0700";
              }
            ];
          };
        })
      ];

    sops.secrets = {
      "postgresql/passwd_file" = {
        sopsFile = rootPath + "/secrets/default.yaml";
        owner = "postgres";
      };
      "postgresql/rustic_env_file" = {
        sopsFile = rootPath + "/secrets/default.yaml";
        owner = "postgres";
      };
    };
  };
}
