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
  cfg = config.yakumo.services.kanidm;
in
{
  options.yakumo.services.kanidm = {
    enable = mkEnableOption "kanidm";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable (
    let
      kanidmCfg = config.services.kanidm;
    in
    {
      services.kanidm = {
        enableClient = true;
        enablePam = true;
        enableServer = true;
        clientSettings.uri = "http://127.0.0.1:8080";
        serverSettings = {
          inherit (cfg) domain;
          bindaddress = "127.0.0.1:8443";
          ldapbindaddress = null; # Default: null
          db_path = "/var/lib/kanidm/kanidm.db";
          log_level = "info"; # Default: 'info' (Options: 'debug', 'trace')
          origin = "https://idm.example.org";
          role = "WriteReplica"; # Default: 'WriteReplica' (Options: 'WriteReplicaNoUI', 'ReadOnlyReplica')
          tls_chain = "path/to/tls_chain";
          tls_key = "path/to/tls_key";
          online_backup = {
            path = "/var/lib/kanidm/backups";
            # Schedule backups in cron format.
            schedule = "00 22 * * *";
            # Specify the number of backups to keep. 0 results in no backup.
            versions = 0; # Default: 0
          };
        };
        unixSettings = {
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
          adminPasswordFile = config.sops.secrets.xxx.path;
          idmAdminPasswordFile = config.sops.secrets.xxx.path;
          # Auto-remove an entity from Kanidm when deleting them in this provisioning config.
          autoRemove = true; # Default: true
          instanceUrl = "https://localhost:8443";
          extraJsonFile = "path/to/provision.json";
          groups = { };
          persons = { };
          systems.oauth2 = { };
        };
      };

      services.caddy.virtualHosts = {
        "${cfg.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${kanidmCfg.bindaddress}
          '';
        };
      };
    }
  );
}
