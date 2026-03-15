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
    mkMerge
    ;
  cfg = config.yakumo.services.kanidm;
  meta = config.yakumo.services.metadata.kanidm;
  headscaleMeta = config.yakumo.services.metadata.headscale;
in
{
  options.yakumo.services.kanidm = {
    enable = mkEnableOption "kanidm";
  };

  config = mkIf cfg.enable {
    services.kanidm = {
      enableClient = true;
      enablePam = true;
      enableServer = true;
      # Specify the Kanidm server address.
      clientSettings.uri = cfg.serverSettings.origin;
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
          # Specify the number of backups to keep. 0 results in no backup.
          versions = 7; # Default: 0
        };
      };
      unixSettings = {
        # Set a path to HSM (Hardware Security Module) pin.
        hsm_pin_path = "/var/cache/kanidm-unixd/hsm-pin";
        # Add Kanidm groups that are allowed to login using PAM.
        kanidm.pam_allowed_login_groups = [
          "my_pam_group"
        ];
      };
      provision = {
        enable = true;
        # Allow invalid certificates when provisioning the target instance if true.
        # By default, this is only allowed when the instanceUrl is localhost.
        # Dangerous if used with an external URL.
        acceptInvalidCerts = false;
        adminPasswordFile = config.sops.secrets.kanidm_admin_passwd.path;
        idmAdminPasswordFile = config.sops.secrets.kanidm_idm_admin_passwd.path;
        # Auto-remove an entity from Kanidm when deleting them in this provisioning config.
        autoRemove = true; # Default: true
        instanceUrl = "https://${meta.bindAddress}";
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
        systems.oauth2 = {
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
                "groups"
              ];
            };
            # Add additional claims based on which Kanidm groups
            # an authenticating party belongs to.
            # https://kanidm.github.io/kanidm/master/integrations/oauth2/custom_claims.html#custom-claim-maps
            claimMaps = { };
          };
        };
      };
    };

    yakumo = mkMerge [
      {
        services.metadata.kanidm.reverseProxy = {
          caddyIntegration.enable = true;
        };
      }
      (mkIf config.yakumo.system.persistence.yosuga.enable {
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
  };
}
