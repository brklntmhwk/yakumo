# WIP
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.services.immich;
in
{
  options.yakumo.services.immich = {
    enable = mkEnableOption "immich";
  };

  config = mkIf cfg.enable (
    let
      pgBackupDir = "/var/backup/postgresql/immich";
    in
    {
      services.immich = {
        enable = true;
        group = "immich"; # Default: 'immich'
        user = "immich"; # Default: 'immich'
        host = "localhost"; # Default: 'localhost'
        port = 2283; # Default: 2283
        openFirewall = false; # Default: false
        # Specify device paths to hardware acceleration devices that
        # immich should have access to.
        # This is helpful when transcoding media files.
        # `[ ]` (Empty list) will disallow all devices using `PrivateDevices`.
        # Give access to all devices if set to null.
        accelerationDevices = [ ];
        # For the valid env variables, see:
        # https://docs.immich.app/install/environment-variables/
        environment = { };
        # Specify the directory used to store media files.
        # Ensure to create it manually and give the immich user the R&W permissions
        # if not using the default one.
        mediaLocation = "/var/lib/immich";
        secretsFile = config.sops.secrets.xxx.path;
        database = {
          enable = true;
          createDB = true; # Default: true
          name = "immich"; # Default: 'immich'
          user = "immich"; # Default: 'immich'
          # Specify the hostname or address of the PostgreSQL server.
          host = "/run/postgresql"; # Default: '/run/postgresql'
          port = 5432; # Default: 5432
          # Set this to false if you use VectorChord instead.
          enableVectors = false;
          enableVectorChord = true; # Default: true
        };
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
          newVersionCheck.enabled = false; # Default: false
          # Domain for publicly shared links, including http(s)://.
          server.externalDomain = ""; # Default: ''
        };
      };

      yakumo.services.rustic.backups = {
        immich = {
          environmentFile = config.sops.secrets.xxx.path;
          timerConfig = {
            OnCalendar = "*-*-* 04:00:00"; # Run daily at 4 a.m.
            Persistent = true;
          };
          settings = {
            repository = "";
            backup = {
              sources = [
                config.services.immich.mediaLocation
                pgBackupDir
              ];
            };
            forget = {
              keep-daily = 14;
              keep-weekly = 4;
              keep-monthly = 12;
              keep-yearly = 2;
              prune = true;
            };
          };
        };
      };

      # Handle the Immich PostgreSQL DB dump before Rustic runs.
      systemd.services."rustic-backups-immich" = {
        preStart = ''
          mkdir -p ${pgBackupDir}
          ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump -Fc immich > ${pgBackupDir}/immich.dump
        '';
      };
    }
  );
}
