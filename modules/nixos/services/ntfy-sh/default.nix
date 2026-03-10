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
    ;
  cfg = config.yakumo.services.ntfy-sh;
  meta = config.yakumo.services.metadata.ntfy-sh;
in
{
  options.yakumo.services.ntfy-sh = {
    enable = mkEnableOption "ntfy-sh";
  };

  config = mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      group = "ntfy-sh"; # Default: 'ntfy-sh'
      user = "ntfy-sh"; # Default: 'ntfy-sh'
      environmentFile = config.sops.secrets.ntfy_env.path; # Default: null
      # For the available settings, see:
      # https://docs.ntfy.sh/config/#config-options
      settings = {
        base-url = "https://${meta.domain}";
        # https://docs.ntfy.sh/config/#ios-instant-notifications
        upstream-base-url = "https://ntfy.sh";
        attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
        auth-default-access = "deny-all";
        auth-file = "/var/lib/ntfy-sh/user.db";
        cache-file = "/var/lib/ntfy-sh/cache.db";
        # By default, ntfy listens on :80 (IPv4-only). If you want to listen on
        # an IPv6 address, you need to explicitly set the listen-http and/or
        # listen-https options to an IPv6 address (e.g. [::]:80).
        # To listen on IPv4 and IPv6, you must run ntfy behind a reverse proxy.
        listen-http = meta.bindAddress;
        behind-proxy = true;
        enable-login = true;
      };
    };

    yakumo.services.metadata.ntfy-sh.reverseProxy = {
      caddyIntegration = {
        enable = true;
        # https://docs.ntfy.sh/config/#nginxapache2caddy
        extraConfig = ''
          reverse_proxy ${meta.bindAddress}

          # Redirect HTTP to HTTPS, but only for GET topic addresses, since we want
          # it to work with curl without the annoying https:// prefix
          @httpget {
              protocol http
              method GET
              path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
          }
          redir @httpget https://{host}{uri}
        '';
      };
    };
  };
}
