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
  cfg = config.yakumo.services.paperless-ngx;
in
{
  options.yakumo.services.paperless-ngx = {
    enable = mkEnableOption "paperless-ngx";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable (
    let
      paperlessCfg = config.services.paperless;
    in
    {
      services.paperless = {
        enable = true;
        address = "127.0.0.1";
        user = "paperless"; # Default: 'paperless'
        consumptionDir = "${paperlessCfg.dataDir}/consume";
        # Allow all users can write to the consumption directory if set to true.
        consumptionDirIsPublic = false; # Default: false
        dataDir = "/var/db/paperless";
        mediaDir = "${paperlessCfg.dataDir}/media";
        domain = cfg.domain; # Default: null
        environmentFile = config.sops.secrets.xxx.path; # Default: null
        passwordFile = "/run/keys/paperless-password";
        port = 28981; # Default: 28981
        # Configure local PostgreSQL DB server.
        database.createLocally = true; # Default: false
        exporter = {
          enable = true; # Default: false
          directory = "${paperlessCfg.dataDir}/export";
          # Schedule when to run the exporter.
          onCalendar = "01:30:00";
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

      yakumo.services.rustic.backups = {
        paperless = {
          environmentFile = config.sops.secrets.xxx.path;
          timerConfig = {
            OnCalendar = "*-*-* 02:30:00"; # Run daily at 2:30 a.m.
            Persistent = true;
          };
          settings = {
            repository = "";
            backup = {
              sources = [
                paperlessCfg.exporter.directory
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

      services.caddy.virtualHosts = {
        "${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy ${paperlessCfg.address}:${paperlessCfg.port}
          '';
        };
      };
    }
  );
}
