# WIP
{
  config,
  lib,
  murakumo,
  rootPath,
  rootMeta,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkForce
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
      inherit (lib) elem;
      inherit (meta) bindAddress domain;
      kaniCfg = config.services.kanidm;
      dataDir = "/var/lib/kanidm";
    in
    mkMerge [
      {
        assertions =
          let
            inherit (murakumo.assertions) assertServiceUp;
          in
          [
            (assertServiceUp "kanidm" rootMeta.allServices)
          ];

        services.kanidm = (
          let
            acmeCertsDir = config.security.acme.certs.${domain}.directory;
          in
          {
            enableClient = true;
            clientSettings.uri = kaniCfg.serverSettings.origin;
            enableServer = true;
            # Required: `domain`, `origin`, `tls_chain`, `tls_key`.
            # https://kanidm.github.io/kanidm/stable/server_configuration.html
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
            #     # Required: `domain`, `origin`, `tls_chain`, `tls_key`.
            #     # https://kanidm.github.io/kanidm/stable/server_configuration.html
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
            #         # Run daily at 22:00 p.m. (UTC)
            #         schedule = "00 22 * * *"; # Default: '00 22 * * *'
            #         # Specify the number of backups to keep. 0 results in no backup.
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
              # These default admin accounts exist to allow the server to be bootstrapped
              # and accessed in emergencies. Not intented for daily use.
              # `admin` manages Kanidm's configuration.
              adminPasswordFile = config.sops.secrets."kanidm/admin_passwd".path;
              # `idm_admin` manages accounts and groups in Kanidm.
              idmAdminPasswordFile = config.sops.secrets."kanidm/idm_admin_passwd".path;
              # People (Persons) accounts are intented for day-to-day use by humans
              # unlike the default admin accounts.
              # https://kanidm.github.io/kanidm/stable/accounts/people_accounts.html
              persons = map (u: {
                "${u.username}" = {
                  displayName = u.name;
                  legalName = u.name;
                  mailAddresses = [
                    u.email
                  ];
                  groups = [
                    "headscale.access"
                  ];
                };
              }) rootMeta.users;
              # https://kanidm.github.io/kanidm/stable/accounts/groups.html
              groups = {
                "forgejo.access" = { };
                "forgejo.admins" = { };
                "grafana.access" = { };
                "grafana.admins" = { };
                "grafana.editors" = { };
                "grafana.server_admins" = { };
                "headscale.access" = { };
                "mealie.access" = { };
                "mealie.admins" = { };
                "paperless.access" = { };
              };
              # https://kanidm.github.io/kanidm/stable/integrations/oauth2.html
              systems.oauth2 =
                let
                  inherit (murakumo.utils) formatString;

                  mkOauth2Resource =
                    name: fn:
                    let
                      resourceMeta = config.yakumo.services.metadata.${name};
                      resourceAttrs = fn resourceMeta;
                    in
                    mkIf (elem name rootMeta.allServices) {
                      ${name} = {
                        displayName = mkDefault (formatString name);
                        originLanding = mkDefault "https://${resourceMeta.domain}/";
                        preferShortUsername = mkDefault true;
                        basicSecretFile = mkForce config.sops.secrets."kanidm/${name}_oauth2_client_secret".path;
                      }
                      // resourceAttrs;
                    };
                in
                mkMerge [
                  (mkOauth2Resource "forgejo" (meta: {
                    originUrl = [ "https://${meta.domain}/user/oauth2/kanidm/callback" ];
                    # Map Kanidm groups to returned oauth scopes.
                    # Scope mappings exist to control who can access what resources.
                    # https://kanidm.github.io/kanidm/stable/integrations/oauth2.html#scope-relationships
                    scopeMaps = {
                      "forgejo.access" = [
                        "openid"
                        "email"
                        "profile"
                      ];
                    };
                    # Add additional claims based on which Kanidm groups an authenticating
                    # party belongs to.
                    # https://kanidm.github.io/kanidm/master/integrations/oauth2/custom_claims.html#custom-claim-maps
                    claimMaps.groups = {
                      joinType = "array";
                      valuesByGroup = {
                        "forgejo.admins" = [ "admin" ];
                      };
                    };
                  }))
                  (mkOauth2Resource "grafana" (meta: {
                    originUrl = [ "https://${meta.domain}/login/generic_oauth" ];
                    scopeMaps = {
                      "grafana.access" = [
                        "openid"
                        "email"
                        "profile"
                      ];
                    };
                    claimMaps.groups = {
                      joinType = "array";
                      valuesByGroup = {
                        "grafana.editors" = [ "editor" ];
                        "grafana.admins" = [ "admin" ];
                        "grafana.server-admins" = [ "server_admin" ];
                      };
                    };
                  }))
                  (mkOauth2Resource "headscale" (meta: {
                    originUrl = [ "https://${meta.domain}/oidc/callback" ];
                    scopeMaps = {
                      "headscale.access" = [
                        "openid"
                        "email"
                        "profile"
                      ];
                    };
                  }))
                  (mkOauth2Resource "mealie" (meta: {
                    originUrl = [ "https://${meta.domain}/login" ];
                    scopeMaps = {
                      "mealie.access" = [
                        "openid"
                        "email"
                        "profile"
                        "groups"
                      ];
                    };
                  }))
                  (mkOauth2Resource "paperless-ngx" (meta: {
                    originUrl = [
                      "https://${meta.domain}/accounts/oidc/kanidm/login/callback/"
                    ];
                    scopeMaps = {
                      "paperless.access" = [
                        "openid"
                        "email"
                        "profile"
                        "groups"
                      ];
                    };
                  }))
                ];
            };
          }
        );

        yakumo =
          let
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
            (mkIf (elem "rustic" rootMeta.allServices) {
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
                      keep-daily = 14;
                      keep-weekly = 8;
                      keep-monthly = 12;
                      keep-yearly = 3;
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
          "kanidm/forgejo_oauth2_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "forgejo.service" ];
          };
          "kanidm/grafana_oauth2_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "grafana.service" ];
          };
          "kanidm/headscale_oauth2_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "headscale.service" ];
          };
          "kanidm/mealie_oauth2_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "mealie.service" ];
          };
          "kanidm/paperless-ngx_oauth2_client_secret" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "kanidm";
            restartUnits = [ "paperless-web.service" ];
          };
        };
      }
    ]
  );
}
