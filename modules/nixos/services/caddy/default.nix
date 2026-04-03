# WIP.
{
  config,
  lib,
  rootPath,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.yakumo.services.caddy;
  systemRole = config.yakumo.system.role;
in
{
  options.yakumo.services.caddy = {
    enable = mkEnableOption "caddy";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = systemRole == "server";
        message = "System role must be server to use Caddy";
      }
      {
        assersion = cfg.enable -> config.yakumo.security.acme.enable;
        message = "ACME must be enabled if using Caddy";
      }
    ];

    services.caddy = {
      # Specify your email address, which will be used when creating an ACME account
      # with your CA.
      inherit (config.security.acme.defaults) email; # Default: null
      enable = true;
      # Reload Caddy instead of restarting it when config file changes.
      enableReload = true; # Default: true
      group = "caddy"; # Default: 'caddy'
      user = "caddy"; # Default: 'caddy'
      environmentFile = config.sops.secrets."caddy/env_file".path; # Default: null
      dataDir = "/var/lib/caddy";
      logDir = "/var/log/caddy";
      # See: https://caddyserver.com/docs/caddyfile/options#log
      logFormat = ''
        level ERROR
      '';
      # Specify the URL to the ACME CA's (Certificate Authority's) directory.
      # For testing or dev, setting this to the following for Let's Encrypt's staging
      # endpoint is recommended:
      # https://acme-staging-v02.api.letsencrypt.org/directory
      # Prod: null should be preferred as it omits the `acme_ca` option to enable
      # automatic issuer fallback.
      # https://caddyserver.com/docs/caddyfile/options#acme-ca
      acmeCA = null; # Default: null
      # Prefer saved config over any specified config passed with `--config`.
      resume = false; # Default: false
      # This morphs into Caddyfile unlike 'services.caddy.settings'
      # (Caddy JSON configuration file).
      # configFile = {};
      # This will be appended to the resulting Caddyfile.
      extraConfig = "";
    };

    # Add the Caddy service user to the global ACME group so Caddy can read
    # every ACME certificate.
    users.groups.acme.members = [ "caddy" ];

    yakumo =
      let
        yosugaCfg = config.yakumo.system.persistence.yosuga;
        caddyCfg = config.services.caddy;
      in
      mkMerge [
        (mkIf yosugaCfg.enable {
          system.persistence.yosuga = {
            directories = [
              {
                inherit (caddyCfg) group user;
                path = caddyCfg.dataDir;
                mode = "0700";
              }
              {
                inherit (caddyCfg) group user;
                path = caddyCfg.logDir;
                mode = "0700";
              }
            ];
          };
        })
      ];

    sops.secrets = {
      "caddy/env_file" = {
        sopsFile = rootPath + "/secrets/default.yaml";
      };
    };
  };
}
