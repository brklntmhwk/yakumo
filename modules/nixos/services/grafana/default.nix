# WIP
{
  config,
  lib,
  pkgs,
  flakeRoot,
  ...
}:

let
  inherit (lib)
    elem
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    types
    ;
  cfg = config.yakumo.services.grafana;
  meta = config.yakumo.services.metadata.grafana;
  grafanaStack = [
    "loki"
    "tempo"
  ];
in
{
  options.yakumo.services.grafana = {
    enable = mkEnableOption "grafana";
    stack = mkOption {
      type = types.listOf (types.enum grafanaStack);
      default = [ ];
      description = "";
      example = [
        "loki"
      ];
    };
  };

  config = mkIf cfg.enable (
    let
      sopsCfg = config.yakumo.secrets.sops;
    in
    mkMerge [
      {
        services.grafana = {
          enable = true;
          dataDir = "/var/lib/grafana";
          openFirewall = false; # Default: false
          # Install these Grafana plugins declaratively.
          # If set, plugins cannot be installed manually.
          declarativePlugins =
            builtins.attrValues {
              inherit (pkgs) fetzerch-sunandmoon-datasource;
            }
            ++ optional (elem "loki" cfg.stack) pkgs.grafana-lokiexplore-app
            ++ optional config.yakumo.services.mosquitto.enable pkgs.grafana-mqtt-datasource;
          provision = {
            enable = true; # Default: false
            alerting = {
              # We don't use the path option, but the settings options here for each.
              contactPoints = {
                settings = {
                  apiVersion = 1; # Default: 1
                  contactPoints = [ ];
                  deleteContactPoints = [ ];
                };
              };
              muteTimings = {
                settings = {
                  apiVersion = 1; # Default: 1
                  muteTimes = [ ];
                  deleteMuteTimes = [ ];
                };
              };
              policies = {
                settings = {
                  apiVersion = 1; # Default: 1
                  policies = [ ];
                  resetPolicies = [ ];
                };
              };
              rules = {
                settings = {
                  apiVersion = 1; # Default: 1
                  groups = [ ];
                  deleteRules = [ ];
                };
              };
              templates = {
                settings = {
                  apiVersion = 1; # Default: 1
                  templates = [ ];
                  deleteTemplates = [ ];
                };
              };
            };
            # See: https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards
            dashboards = {
              # We don't use the path option, but the settings option here.
              settings = { };
            };
            # See: https://grafana.com/docs/grafana/latest/administration/provisioning/#data-sources
            datasources = {
              # We don't use the path option, but the settings option here.
              settings = { };
            };
          };
          # We don't manually configure the settings.paths & settings.plugins options
          # and other sub-options but leave them up to the default.
          settings = {
            analytics = {
              check_for_updates = false; # Default: false
              feedback_links_enabled = true; # Default: true
              reporting_enabled = false; # Default: false
            };
            database =
              let
                pgMeta = config.yakumo.services.metadata.postgresql;
              in
              {
                type = "postgres"; # Default: 'sqlite3' (Options: 'postgres', 'mysql')
                name = "grafana"; # Default: 'grafana'
                host = pgMeta.bindAddress; # Default: '127.0.0.1:3306'
                path = "${config.services.grafana.dataDir}/data/grafana.db";
                # Not applicable for 'sqlite3'.
                user = "grafana"; # Default: 'grafana'
                ca_cert_path = null; # Default: null
                client_cert_path = null; # Default: null
                client_key_path = null; # Default: null
                cache_mode = "private"; # Default: 'private' (Options: 'shared')
                conn_max_lifetime = 14400; # Default: 14400
                isolation_level = null; # Default: null
                locking_attempt_timeout_sec = 0; # Default: 0
                log_queries = false; # Default: false
                max_idle_conn = 2; # Default: 2
                max_open_conn = 0; # Default: 0
                query_retries = 0; # Default: 0
                server_cert_name = null; # Default: null
                # (Options: 'require', 'verify-full', 'true', 'false', 'skip-verify')
                ssl_mode = "disable"; # Default: 'disable'
                transaction_retries = 5; # Default: 5
              };
            security = {
              admin_email = "";
              admin_user = "admin"; # Default: 'admin'
              allow_embedding = false; # Default: false
              content_security_policy = false; # Default: false
              content_security_policy_report_only = false; # Default: false
              cookie_samesite = "lax"; # Default: 'lax' (Options: 'strict', 'none', 'disabled')
              cookie_secure = false; # Default: false
              csrf_additional_headers = [ ];
              csrf_trusted_origins = [ ];
              data_source_proxy_whitelist = [ ];
              disable_brute_force_login_protection = false; # Default: false
              disable_gravatar = false; # Default: false
              disable_initial_admin_creation = false; # Default: false
              strict_transport_security = false; # Default: false
              strict_transport_security_max_age_seconds = 86400; # Default: 86400
              strict_transport_security_preload = false; # Default: false
              strict_transport_security_subdomains = false; # Default: false
              x_content_type_options = true; # Default: true
              x_xss_protection = false; # Default: false
            };
            server = {
              inherit (meta) domain; # Default: 'localhost'
              protocol = "http"; # Default: 'http' (Options: 'https', 'h2', 'socket')
              cdn_url = null; # Default: null
              # These 'cert_' prefixed options are valid only when
              # the protocol option value is either 'https' or 'h2'.
              cert_file = null; # Default: null
              cert_key = null; # Default: null
              enable_gzip = false; # Default: false
              enforce_domain = false; # Default: false
              http_addr = meta.address; # '127.0.0.1'
              http_port = meta.port; # Default: 3000
              # Set the maximum time in the duration format (e.g., 5s/5m/5ms) before
              # timing out read of an incoming request and closing idle connections.
              # '0' means no timeout for reading the request.
              read_timeout = "0"; # Default: '0'
              # Specify the full URL to access Grafana from a web browser.
              # Default: '%(protocol)s://%(domain)s:%(http_port)s/'
              root_url = "%(protocol)s://%(domain)s:%(http_port)s/";
              router_logging = false; # Default: false
              # Serve Grafana from the subpath specified in the root_url option.
              # e.g., Enable this and set the root_url option to
              # 'http://localhost:3000/grafana', then Grafana will be accessible on
              # that URL. If accessed without the subpath, Grafana will redirect to
              # an URL with the subpath.
              serve_from_sub_path = false; # Default: false
              # Specify the path where the socket is created.
              # This and the following options prefixed with 'socket_' are valid
              # only when the protocol option value is 'socket'.
              socket = "/run/grafana/grafana.sock";
              socket_gid = -1; # Default: -1
              socket_mode = "0660"; # Default: 0660
              static_root_path = "${config.services.grafana.package}/share/grafana/public";
            };
            smtp = {
              # Set this to true if you want to have Grafana sending notifications
              # via email.
              enabled = false; # Default: false
              host = "localhost:25"; # Default: 'localhost:25'
              user = null; # Default: null
              cert_file = null; # Default: null
              ehlo_identity = null; # Default: null
              from_name = "Grafana"; # Default: 'Grafana'
              from_address = "admin@grafana.localhost";
              key_file = null; # Default: null
              skip_verify = false; # Default: false
              startTLS_policy = null; # Default: null
            };
            users = {
              allow_org_create = false; # Default: false
              allow_sign_up = false; # Default: false
              auto_assign_org = true; # Default: true
              auto_assign_org_id = 1; # Default: 1
              auto_assign_org_role = "Viewer"; # Default: 'Viewer' (Options: 'Editor', 'Admin')
              default_language = "en-US"; # Default: 'en-US'
              default_theme = "dark"; # Default: 'dark' (Options: 'light', 'system')
              hidden_users = ""; # Default: ''
              home_page = ""; # Default: ''
              login_hint = "email or username"; # Default: 'email or username'
              password_hint = "password"; # Default: 'password'
              # Specify the time duration of user invitations in the duration format
              # (e.g., 6h/2d/1w).
              # The minimum supported duration is '15m' (15 minutes).
              user_invite_max_lifetime_duration = "24h"; # Default: '24h'
              # Require email validation before sign-up completes.
              verify_email_enabled = false; # Default: false
              # Allow viewers to use Explore and temporarily edit panels in dashboards
              # (They still can't save their changes).
              viewers_can_edit = false; # Default: false
            };
          };
        };

        yakumo.services.metadata.grafana.reverseProxy = {
          caddyIntegration.enable = true;
        };
      }
      (mkIf sopsCfg.enable {
        sops.secrets = {
          grafana_admin_passwd = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
            owner = "grafana";
          };
          grafana_secret_key = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
            owner = "grafana";
          };
          grafana_db_passwd = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
            owner = "grafana";
          };
          grafana_smtp_passwd = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
            owner = "grafana";
          };
        };

        services.grafana = {
          settings.database = {
            # Not applicable for 'sqlite3'.
            password = config.sops.secrets.grafana_db_passwd.path; # Default: ''
          };
          security = {
            admin_password = config.sops.secrets.grafana_admin_passwd.path;
            secret_key = config.sops.secrets.grafana_secret_key.path; # Default: 'SW2YcwTIb9zpOOhoPsMm'
          };
          smtp.password = config.sops.secrets.grafana_smtp_passwd.path; # Default: ''
        };
      })
      (mkIf (elem "loki" cfg.stack) {
        services.loki = {
          enable = true;
          group = "loki"; # Default: 'loki'
          user = "loki"; # Default: 'loki'
          dataDir = "/var/lib/loki";
          extraFlags = [ ];
          # We use this Nix-representable JSON format instead of the configFile option.
          configuration = { };
        };
      })
      (mkIf (elem "tempo" cfg.stack) {
        services.tempo = {
          enable = true;
          extraFlags = [ ];
          # We use this Nix-representable YAML format instead of the configFile option.
          settings = { };
        };
      })
    ]
  );
}
