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
  cfg = config.yakumo.services.kanidm;
  meta = config.yakumo.services.metadata.kanidm;
in
{
  options.yakumo.services.kanidm = {
    enable = mkEnableOption "kanidm";
  };

  config = mkIf cfg.enable (
    let
      kaniCfg = config.services.kanidm;
      headscaleCfg = config.yakumo.services.headscale;
    in
    mkMerge [
      {
        services.kanidm = {
          enableClient = true;
          clientSettings.uri = kaniCfg.serverSettings.origin;
          enableServer = true;
          serverSettings = {
            inherit (meta) domain;
            bindaddress = meta.bindAddress;
            ldapbindaddress = null; # Default: null
            db_path = "/var/lib/kanidm/kanidm.db";
            log_level = "info"; # Default: 'info' (Options: 'debug', 'trace')
            origin = "https://${meta.domain}";
            role = "WriteReplica"; # Default: 'WriteReplica' (Options: 'WriteReplicaNoUI', 'ReadOnlyReplica')
            tls_chain = "path/to/tls_chain";
            tls_key = "path/to/tls_key";
            online_backup = {
              path = "/var/lib/kanidm/backups";
              # Schedule backups in cron format.
              schedule = "00 22 * * *";
              # Specify \the number of backups to keep. 0 results in no backup.
              versions = 7; # Default: 0
            };
          };
          # client = {
          #   enable = true; # Formerly `services.kanidm.enableClient`.
          #   # Specify the Kanidm server address.
          #   settings.uri = kaniCfg.server.settings.origin; # Formerly `services.kanidm.clientSettings.uri`.
          # };
          # server = {
          #   enable = true; # Formerly `services.kanidm.enableServer`.
          #   # Formerly `services.kanidm.serverSettings`.
          #   settings = {
          #     inherit (meta) domain;
          #     bindaddress = meta.bindAddress;
          #     ldapbindaddress = null; # Default: null
          #     db_path = "/var/lib/kanidm/kanidm.db";
          #     log_level = "info"; # Default: 'info' (Options: 'debug', 'trace')
          #     origin = "https://${meta.domain}";
          #     role = "WriteReplica"; # Default: 'WriteReplica' (Options: 'WriteReplicaNoUI', 'ReadOnlyReplica')
          #     tls_chain = "path/to/tls_chain";
          #     tls_key = "path/to/tls_key";
          #     online_backup = {
          #       path = "/var/lib/kanidm/backups";
          #       # Schedule backups in cron format.
          #       schedule = "00 22 * * *";
          #       # Specify \the number of backups to keep. 0 results in no backup.
          #       versions = 7; # Default: 0
          #     };
          #   };
          # };
          # unix = {
          #   enable = true; # Formerly `services.kanidm.enablePam`.
          #   # Formerly `services.kanidm.unixSettings`.
          #   settings = {
          #     # Set a path to HSM (Hardware Security Module) pin.
          #     hsm_pin_path = "/var/cache/kanidm-unixd/hsm-pin";
          #     # Add Kanidm groups that are allowed to login using PAM.
          #     kanidm.pam_allowed_login_groups = [
          #       "my_pam_group"
          #     ];
          #   };
          # };
          provision = {
            enable = true;
            # Allow invalid certificates when provisioning the target instance if true.
            # By default, this is only allowed when the instanceUrl is localhost.
            # Dangerous if used with an external URL.
            acceptInvalidCerts = false;
            # Auto-remove an entity from Kanidm when deleting them in this provisioning config.
            autoRemove = true; # Default: true
            instanceUrl = "https://${meta.bindAddress}";
            adminPasswordFile = config.sops.secrets."kanidm/admin_passwd".path;
            idmAdminPasswordFile = config.sops.secrets."kanidm/idm_admin_passwd".path;
            groups = {
              vpn_users = { };
            };
            persons = {
              # TODO: Make this an option.
              otogaki = {
                displayName = "Ohma Togaki";
                legalName = "Ohma Togaki";
                mailAddresses = [
                  "contact@younagi.dev"
                ];
                groups = [
                  "vpn_users"
                ];
              };
            };
            systems.oauth2 =
              let
                headscaleMeta = config.yakumo.services.metadata.headscale;
              in
              mkMerge [
                (mkIf headscaleCfg.enable {
                  headscale = {
                    displayName = "Headscale VPN";
                    originLanding = "https://${headscaleMeta.domain}";
                    originUrl = [
                      "https://${headscaleMeta.domain}/oidc/callback"
                    ];
                    basicSecretFile = config.sops.secrets.headscale_oidc_secret.path;
                    # Map Kanidm groups to returned oauth scopes.
                    # https://kanidm.github.io/kanidm/stable/integrations/oauth2.html#scope-relationships
                    scopeMaps = {
                      "vpn_users" = [
                        "openid"
                        "profile"
                        "email"
                      ];
                    };
                    # Add additional claims based on which Kanidm groups an authenticating
                    # party belongs to.
                    # https://kanidm.github.io/kanidm/master/integrations/oauth2/custom_claims.html#custom-claim-maps
                    claimMaps = { };
                  };
                })
              ];
          };
        };

        yakumo =
          let
            rusticCfg = config.yakumo.services.rustic;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata.kanidm.reverseProxy = {
                caddyIntegration.enable = true;
              };
            }
            (mkIf rusticCfg.enable {
              services.rustic.backups = {
                kanidm = {
                  environmentFile = config.sops.secrets."kanidm/rustic_env_file".path;
                  timerConfig = {
                    # Run daily at 11:30 PM, safely after Kanidm's 10:00 PM internal backup.
                    OnCalendar = "*-*-* 23:30:00";
                    Persistent = true;
                  };
                  settings = {
                    repository = "s3:https://your-s3-endpoint/bucket/kanidm";
                    backup = {
                      sources = [
                        # Target the native online_backup path, not the live database.
                        kaniCfg.serverSettings.online_backup.path
                        # kaniCfg.server.settings.online_backup.path
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
                    path = "/var/lib/kanidm";
                    user = "kanidm";
                    group = "kanidm";
                    mode = "0700";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          "kanidm/admin_passwd" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
          };
          "kanidm/idm_admin_passwd" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
          };
          "kanidm/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
          };
          "kanidm/headscale_oidc_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "headscale.service" ];
          };
          "kanidm/mealie_oidc_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "mealie.service" ];
          };
        };
      }
    ]
  );
}
