# WIP
{
  config,
  lib,
  flakeRoot,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.stalwart-mail;
  meta = config.yakumo.services.metadata.stalwart-mail;
in
{
  options.yakumo.services.stalwart-mail = {
    enable = mkEnableOption "stalwart-mail";
  };

  config = mkIf cfg.enable (
    let
      stalwartCfg = config.services.stalwart-mail;
      sopsCfg = config.yakumo.secrets.sops;
    in
    mkMerge [
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

        yakumo =
          let
            rusticCfg = config.yakumo.services.rustic;
          in
          mkMerge [
            {
              services.metadata = {
                stalwart-mail.reverseProxy = {
                  caddyIntegration.enable = true;
                };
              };
            }
            (mkIf rusticCfg.enable {
              services.rustic.backups = {
                stalwart = {
                  environmentFile = mkIf sopsCfg config.sops.secrets.rustic_stalwart_env.path;
                  timerConfig = {
                    OnCalendar = "*-*-* 03:00:00"; # Run daily at 3 a.m.
                    Persistent = true;
                  };
                  settings = {
                    repository = "s3:https://your-s3-endpoint/bucket/stalwart-mail";
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
            })
          ];
      }
      (mkIf sopsCfg.enable {
        sops.secrets = {
          rustic_stalwart_env = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
        };
      })
    ]
  );
}
