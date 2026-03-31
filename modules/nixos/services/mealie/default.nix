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
  cfg = config.yakumo.services.mealie;
  meta = config.yakumo.services.metadata.mealie;
in
{
  options.yakumo.services.mealie = {
    enable = mkEnableOption "mealie";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.mealie = {
        inherit (meta) port; # Default: 9000
        enable = true;
        credentialsFile = config.sops.templates."mealie-secrets.env".path;
        # Setup local PostgreSQL DB server for Mealie.
        # We leave this disabled so host configurations can flexibly customize.
        database.createLocally = false; # Default: false
        listenAddress = meta.address; # Default: '0.0.0.0'
        # https://docs.mealie.io/documentation/getting-started/installation/backend-config/
        settings = {
          BASE_URL = "https://${meta.domain}"; # Default: 'http://localhost:8080'
          TZ = config.time.timeZone; # Default: 'UTC'
          # Specify the time window during which a login/auth token is valid.
          # This must be <= 9600.
          TOKEN_TIME = 9600; # Default: 48 (hours)
          # Whether to allow user sign-up without token.
          ALLOW_SIGNUP = "false"; # Default: 'false'
          SECURITY_MAX_LOGIN_ATTEMPTS = 5; # Default: 5
          SECURITY_USER_LOCKOUT_TIME = 24; # Default: 24 (hours)

          # DB Integration
          DB_ENGINE = "sqlite"; # Default: 'sqlite'

          # OIDC (OpenID Connect) Authentication
          # https://docs.mealie.io/documentation/getting-started/installation/backend-config/#openid-connect-oidc
          # https://docs.mealie.io/documentation/getting-started/authentication/oidc-v2/
          OIDC_AUTH_ENABLED = "true"; # Default: 'false'
          OIDC_SIGNUP_ENABLED = "true"; # Default: 'true'
          OIDC_AUTO_REDIRECT = "true"; # Default: 'false'
          OIDC_REMEMBER_ME = "true"; # Default: 'false'
          OIDC_USER_CLAIM = "preferred_username"; # Default: 'email'
          OIDC_PROVIDER_NAME = "Kanidm"; # Default: 'OAuth'
          OIDC_CONFIGURATION_URL = "https://${meta.domain}/oauth2/openid/mealie/.well-known/openid-configuration"; # Default: ''
          OIDC_USER_GROUP = "mealie.access@${meta.domain}"; # Default: ''
          OIDC_ADMIN_GROUP = "mealie.admins@${meta.domain}"; # Default: ''
          # These should be treated as secrets, so we configure and set them to
          # `credentialsFile` instead.
          # OIDC_CLIENT_ID = "mealie"; # Default: ''
          # OIDC_CLIENT_SECRET = "";
        };
        extraOptions = [ ];
      };

      yakumo =
        let
          dataDir = "/var/lib/private/mealie";
          yosugaCfg = config.yakumo.system.persistence.yosuga;
        in
        mkMerge [
          {
            services.metadata.mealie.reverseProxy = {
              caddyIntegration.enable = true;
            };
          }
          (mkIf rusticCfg.enable {
            services.rustic.backups = {
              mealie = {
                environmentFile = config.sops.secrets."mealie/rustic_env_file".path;
                timerConfig = {
                  OnCalendar = "*-*-* 04:15:00"; # Run daily at 4:15 a.m.
                  Persistent = true;
                };
                settings = {
                  repository = {
                    repository = "s3:https://your-s3-endpoint/bucket/mealie";
                  };
                  backup = {
                    snapshots = [
                      {
                        name = "mealie";
                        sources = [ dataDir ];
                      }
                    ];
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
          (mkIf yosugaCfg.enable {
            system.persistence.yosuga = {
              directories = [
                # Specify the private data directory as the upstream module enables
                # `serviceConfig.DynamicUser` for the Mealie systemd service.
                {
                  path = dataDir;
                  mode = "0700";
                }
              ];
            };
          })
        ];

      sops = {
        secrets = {
          "kanidm/mealie_oidc_client_secret" = { };
          "mealie/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
          };
        };
        templates =
          let
            inherit (lib) optionalString;
            kaniCfg = config.yakumo.services.kanidm;
          in
          {
            "mealie-secrets.env" = {
              content = ''
                OIDC_CLIENT_ID=mealie
                ${optionalString kaniCfg.enable ''
                  OIDC_CLIENT_SECRET=${config.sops.placeholder."kanidm/mealie_oidc_client_secret"}
                ''}
              '';
            };
          };
      };
    }
  ]);
}
