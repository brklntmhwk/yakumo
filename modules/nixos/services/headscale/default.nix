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
  cfg = config.yakumo.services.headscale;
  meta = config.yakumo.services.metadata.headscale;
in
{
  options.yakumo.services.headscale = {
    enable = mkEnableOption "headscale";
  };

  config = mkIf cfg.enable mkMerge [
    {
      services.headscale = {
        inherit (meta)
          address # Default: '127.0.0.1'
          port # Default: 8080
          ;
        enable = true;
        group = "headscale"; # Default: 'headscale'
        user = "headscale"; # Default: 'headscale'
        settings = {
          server_url = "https://${meta.domain}";
          database = {
            # Use SQLite for Headscale in order to avoid this chicken and egg deadlock:
            # - Headscale is expected to be hosted on a cloud VPS, and it needs the
            # connection to a home server that hosts PostgreSQL.
            # - To reach the home server securely, the VPS routes traffic through
            # the Headscale VPN.
            # - The VPN can't start because Headscale hasn't loaded its DB yet!
            type = "sqlite"; # Default: 'sqlite' (Options: 'postgres', 'sqlite3')
            sqlite = {
              path = "/var/lib/headscale/db.sqlite";
              # Enable WAL (Write Ahead Log) mode for SQLite.
              # See: https://www.sqlite.org/wal.html
              write_ahead_log = true; # Default: true
            };
          };
          # DERP (Designated Encrypted Relay for Packets):
          # Tailscale fallback protocol used when direct peer-to-peer connection
          # fails due to strict firewalls, NATs, or missing IPv6.
          # It acts as an encrypted relay for WireGuard packets over HTTPS.
          derp = {
            auto_update_enabled = true;
            paths = [
              # The public Tailscale servers
              "https://controlplane.tailscale.com/derpmap/default"
            ];
            update_frequency = "24h"; # Default: '24h'
            urls = [ ];
            server.private_key_path = "/path/to/derp-server-private.key";
          };
          # DNS (Domain Name System)
          dns = {
            base_domain = meta.domain;
            magic_dns = true; # Default: 'true'
            nameservers.global = config.networking.nameservers;
            # Inject these search domains to Tailscale clients.
            search_domains = [ "yakumo.internal" ];
          };
          # Time before deletion of an inactive ephemeral node.
          ephemeral_node_inactivity_timeout = "30m"; # Default: '30m'
          log = {
            format = "text"; # Default: 'text' (Options: 'json')
            level = "info"; # Default: 'info' (Options: 'debug')
          };
          noise.private_key_path = "/var/lib/headscale/noise_private.key";
          # OIDC (OpenID Connect)
          oidc = {
            allowed_domains = [ ];
            allowed_users = [ ];
            client_secret_path = config.sops.secrets.headscale.path;
            client_id = "Headscale"; # Default: ''
            extra_params = { };
            issuer = "https://"; # Default: ''
            # PKCE (Proof Key for Code Exchange): Prevents
            pkce = {
              enabled = true;
              # Use SHA256 hashed code verifier.
              method = "S256"; # Default: 'S256' (Options: 'plain')
            };
            scope = [
              "openid"
              "profile"
              "email"
            ];
          };
          # ACLs (Access Control Lists)
          policy = {
            mode = "file"; # Default: 'file' (Options: 'database')
            # The path to a HuJSON file that contains ACL policies.
            # Needed only when the mode option is set to 'file'.
            path = "/path/to/acls-file";
          };
          prefixes = {
            # Specify the strategy applied for allocation of IPs to nodes.
            # 'sequential': assigns the next free IP from the previous given IP.
            # 'random': assigns the next free IP from a pseudo-random IP generator (crypto/rand).
            allocation = "sequential"; # Default: 'sequential' (Options: 'random')
            v4 = "100.64.0.0/10"; # Default: '100.64.0.0/10'
            v6 = "fd7a:115c:a1e0::/48"; # Default: 'fd7a:115c:a1e0::/48'
          };
          tls_cert_path = "path/to/tls_cert_path"; # Default: null
          tls_key_path = "path/to/tls_key_path"; # Default: null
          # Domain name to request a TLS certificate for.
          tls_letsencrypt_hostname = "headscale"; # Default: ''
          tls_letsencrypt_challenge_type = "HTTP-01"; # Default: 'HTTP-01' (Options: 'TLS-ALPN-01')
          tls_letsencrypt_listen = ":http"; # Default: ':http'
        };
      };

      yakumo.services.metadata.headscale.reverseProxy = {
        caddyIntegration.enable = true;
      };
    }
  ];
}
