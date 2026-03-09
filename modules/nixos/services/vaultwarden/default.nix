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
  srvMetadata = config.yakumo.services.metadata.vaultwarden;
in
{
  options.yakumo.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable (
    let
      vwCfg = config.services.vaultwarden;
    in
    {
      services.vaultwarden = {
        inherit (srvMetadata) domain;
        enable = true;
        backupDir = "/var/backup/vaultwarden-pg"; # Default: null
        # Use Caddy instead.
        configureNginx = false; # Default: false
        configurePostgres = true; # Default: false
        dbBackend = "postgresql"; # Default: 'sqlite' (Options: 'mysql', 'postgresql')
        environmentFile = config.sops.secrets.xxx.path; # Default: [ ]
        config = {
          ROCKET_ADDRESS = srvMetadata.address;
          ROCKET_PORT = srvMetadata.port;
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
                vwCfg.backupDir
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
          ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump -Fc vaultwarden > ${vwCfg.backupDir}/vaultwarden.dump
        '';
      };

      services.caddy.virtualHosts = {
        "${srvMetadata.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${srvMetadata.bindAddress}
          '';
        };
      };
    }
  );
}
