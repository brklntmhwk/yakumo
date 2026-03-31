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
  cfg = config.yakumo.services.kanidm;
  meta = config.yakumo.services.metadata.kanidm;
in
{
  options.yakumo.services.kanidm = {
    enable = mkEnableOption "kanidm";
  };

  config = mkIf cfg.enable (
    let
      inherit (meta) bindAddress domain;
      kaniCfg = config.services.kanidm;
      headCfg = config.yakumo.services.headscale;
      dataDir = "/var/lib/kanidm";
    in
    mkMerge [
      {
        services.kanidm = (
          let
            acmeCertsDir = config.security.acme.certs.${domain}.directory;
          in
          {
            enableClient = true;
            clientSettings.uri = kaniCfg.serverSettings.origin;
            enableServer = true;
            serverSettings = {
              inherit domain;
              bindaddress = bindAddress;
              ldapbindaddress = null; # Default: null
              origin = "https://${domain}";
              db_path = "${dataDir}/kanidm.db"; # Default: '/var/lib/kanidm/kanidm.db'
              log_level = "info"; # Default: 'info' (Options: 'debug', 'trace')
              role = "WriteReplica"; # Default: 'WriteReplica' (Options: 'WriteReplicaNoUI', 'ReadOnlyReplica')
              tls_chain = "${acmeCertsDir}/fullchain.pem";
              tls_key = "${acmeCertsDir}/key.pem";
              online_backup = {
                # Specify the number of backups to keep. 0 results in no backup.
                versions = 7; # Default: 0
                path = "${dataDir}/backups";
                # Schedule backups in cron format.
                # Run daily at 22:00 p.m. (UTC)
                schedule = "00 22 * * *"; # Default: '00 22 * * *'
              };
            };
            # client = {
            #   enable = true; # Formerly `services.kanidm.enableClient`.
            #   # Specify the Kanidm server address.
            #   settings.uri = kaniCfg.server.settings.origin; # Formerly `services.kanidm.clientSettings.uri`.
            # };
            # server =
            #   let
            #     acmeCertsDir = config.security.acme.certs.${domain}.directory;
            #   in
            #   {
            #     enable = true; # Formerly `services.kanidm.enableServer`.
            #     # Formerly `services.kanidm.serverSettings`.
            #     settings = {
            #       inherit domain;
            #       bindaddress = bindAddress;
            #       ldapbindaddress = null; # Default: null
            #       db_path = "${dataDir}/kanidm.db";
            #       log_level = "info"; # Default: 'info' (Options: 'debug', 'trace')
            #       origin = "https://${domain}";
            #       role = "WriteReplica"; # Default: 'WriteReplica' (Options: 'WriteReplicaNoUI', 'ReadOnlyReplica')
            #       tls_chain = "${acmeCertsDir}/fullchain.pem";
            #       tls_key = "${acmeCertsDir}/key.pem";
            #       online_backup = {
            #         path = "${dataDir}/backups";
            #         # Schedule backups in cron format.
            #         schedule = "00 22 * * *";
            #         # Specify \the number of backups to keep. 0 results in no backup.
            #         versions = 7; # Default: 0
            #       };
            #     };
            #   };
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
              instanceUrl = "https://${bindAddress}";
              adminPasswordFile = config.sops.secrets."kanidm/admin_passwd".path;
              idmAdminPasswordFile = config.sops.secrets."kanidm/idm_admin_passwd".path;
              groups = {
                vpn_users = { };
              };
              persons = map (u: {
                "${u.username}" = {
                  displayName = u.name;
                  legalName = u.name;
                  mailAddresses = [
                    u.email
                  ];
                  groups = [
                    "vpn_users"
                  ];
                };
              }) yakumoMeta.user;
              systems.oauth2 =
                let
                  headMeta = config.yakumo.services.metadata.headscale;
                in
                mkMerge [
                  (mkIf headCfg.enable {
                    headscale = {
                      displayName = "Headscale VPN";
                      originLanding = "https://${headMeta.domain}";
                      originUrl = [
                        "https://${headMeta.domain}/oidc/callback"
                      ];
                      basicSecretFile = config.sops.secrets."kanidm/headscale_oidc_client_secret".path;
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
          }
        );

        yakumo =
          let
            rusticCfg = config.yakumo.services.rustic;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata.kanidm.reverseProxy = {
                caddyIntegration = {
                  enable = true;
                  acme.enable = true;
                };
              };
            }
            (mkIf rusticCfg.enable {
              services.rustic.backups = {
                kanidm = {
                  environmentFile = config.sops.secrets."kanidm/rustic_env_file".path;
                  timerConfig = {
                    # Run daily at 04:15 AM, safely after Kanidm's 10:00 PM internal backup.
                    OnCalendar = "*-*-* 04:15:00";
                    Persistent = true;
                  };
                  settings = {
                    repository = {
                      repository = "s3:https://your-s3-endpoint/bucket/kanidm";
                    };
                    backup = {
                      snapshots = [
                        {
                          name = "kanidm";
                          sources = [
                            # Target the native online_backup path, not the live database.
                            kaniCfg.serverSettings.online_backup.path
                            # kaniCfg.server.settings.online_backup.path
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
                    path = dataDir;
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
