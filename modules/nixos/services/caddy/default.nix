# WIP.
{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
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
    ];

    services.caddy = {
      enable = true;
      # Reload Caddy instead of restarting it when config file changes.
      enableReload = true; # Default: true
      group = "caddy"; # Default: 'caddy'
      user = "caddy"; # Default: 'caddy'
      # Specify your email address, which will be used when creating an ACME account
      # with your CA.
      email = null; # Default: null
      environmentFile = config.sops.secrets.xxx.path; # Default: null
      dataDir = "/var/lib/caddy";
      logDir = "/var/log/caddy";
      # See: https://caddyserver.com/docs/caddyfile/options#log
      logFormat = ''
        level ERROR
      '';
      # Specify the URL to the ACME CA's directory.
      # For testing or dev, setting this to the following for Let's Encrypt's staging
      # endpoint is recommended:
      # https://acme-staging-v02.api.letsencrypt.org/directory
      # Prod: null should be preferred as it omits the `acme_ca` option to enable
      # automatic issuer fallback.
      acmeCA = null; # Default: null
      # Prefer saved config over any specified config passed with `--config`.
      resume = false; # Default: false
      # This morphs into Caddyfile unlike 'services.caddy.settings'
      # (Caddy JSON configuration file).
      # configFile = {};
      extraConfig = "";
    };
  };
}
