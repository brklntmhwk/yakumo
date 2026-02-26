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
  cfg = config.yakumo.services.vaultwarden;
in
{
  options.yakumo.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      backupDir = "/var/backup/vaultwarden-pg"; # Default: null
      # Use Caddy instead.
      configureNginx = false; # Default: false
      configurePostgres = true; # Default: false
      dbBackend = "postgresql"; # Default: 'sqlite' (Options: 'mysql', 'postgresql')
      domain = "";
      environmentFile = config.sops.secrets.xxx.path; # Default: [ ]
      config = {
        ROCKET_ADDRESS = "::1";
        ROCKET_PORT = 8222;
      };
    };

    yakumo.services.rustic.backups = {
      vaultwarden = {
        environmentFile = config.sops.secrets.xxx.path;
        timerConfig = {
          OnCalendar = "*-*-* 03:30:00"; # Run daily at 3:30 a.m.
          Persistent = true;
        };
        settings = {
          repository = "";
          backup = {
            sources = [
              config.services.vaultwarden.backupDir
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

    # Handle the Vaultwarden PostgreSQL DB dump before Rustic runs.
    systemd.services."rustic-backups-vaultwarden" = {
      preStart = ''
        mkdir -p /var/backup/vaultwarden-pg
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump -Fc vaultwarden > ${config.services.vaultwarden.backupDir}/vaultwarden.dump
      '';
    };
  };
}
