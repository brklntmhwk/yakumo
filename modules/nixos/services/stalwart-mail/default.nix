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
    ;
  cfg = config.yakumo.services.stalwart-mail;
  meta = config.yakumo.services.metadata.stalwart-mail;
in
{
  options.yakumo.services.stalwart-mail = {
    enable = mkEnableOption "satlwart-mail";
  };

  config = mkIf cfg.enable (
    let
      stalwartCfg = config.services.stalwart-mail;
    in
    {
      services.stalwart-mail = {
        enable = true;
        openFirewall = false; # Default: false
        dataDir = "/var/lib/stalwart-mail";
        # Set credentials env vars to configure Stalwart-Mail secrets.
        # These secrets can be accessed in configuration values with the macros such as
        # %{file:/run/credentials/stalwart-mail.service/VAR_NAME}%.
        # For the macro syntax, see: https://stalw.art/docs/configuration/macros
        credentials = { };
        # For the available options, see:
        # https://stalw.art/docs/category/configuration/
        settings = {
          # https://stalw.art/docs/auth/authorization/administrator/#fallback-administrator
          authentication.fallback-admin = {
            user = "admin";
            secret = "%{file:/etc/stalwart/admin-pw}%";
          };
          # https://stalw.art/docs/category/server-settings
          server = {
            hostname = cfg.domain;
            tls = {
              enable = true;
              implicit = true;
            };
            listener = {
              smtp = {
                protocol = "smtp";
                bind = "[::]:25";
              };
              submissions = {
                protocol = "smtp";
                bind = "[::]:465";
                tls.implicit = true;
              };
              imaps = {
                protocol = "imap";
                bind = "[::]:993";
                tls.implicit = true;
              };
              jmap = {
                bind = "[::]:8080";
                url = "https://mail.example.org";
                protocol = "http";
              };
              http = {
                # jmap, web interface
                protocol = "http";
                bind = "[::]:8080";
                url = "https://${cfg.domain}";
                use-x-forwarded = true;
              };
              management = {
                bind = [ meta.bindAddress ];
                protocol = "http";
              };
            };
          };
          # https://stalw.art/docs/storage/backends/sqlite
          store.db = {
            type = "sqlite";
            path = "${stalwartCfg.dataDir}/database.sqlite3";
          };
        };
      };

      yakumo.services.rustic.backups = {
        stalwart = {
          environmentFile = config.sops.secrets.stalwart_env.path;
          timerConfig = {
            OnCalendar = "*-*-* 03:00:00"; # Run daily at 3 a.m.
            Persistent = true;
          };
          settings = {
            repository = "";
            backup = {
              sources = [ "/var/lib/stalwart-mail" ];
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

      yakumo.services.metadata.stalwart-mail.reverseProxy = {
        caddyIntegration.enable = true;
      };
    }
  );
}
