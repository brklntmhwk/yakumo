# WIP
{
  config,
  lib,
  pkgs,
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
  kanidmMeta = config.yakumo.services.metadata.kanidm;
in
{
  options.yakumo.services.headscale = {
    enable = mkEnableOption "headscale";
  };

  config = mkIf cfg.enable (mkMerge [
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
            # - We expect Headscale to be hosted on a cloud VPS, and it needs the
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
            # Use the public Tailscale DERP server instead of spinning up a custom
            # embedded DERP server. No need to specify `server.private_key_path`.
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
            client_secret_path = config.sops.secrets.headscale_client_secret.path;
            # Set this in lower case because Kanidm standardizes on lowercase client IDs.
            client_id = "headscale"; # Default: ''
            extra_params = { };
            # Kanidm's specific OIDC issuer URL format requires appending the client ID.
            issuer = "https://${kanidmMeta.domain}/oauth2/openid/headscale"; # Default: ''
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
          policy =
            let
              aclsHuJson = pkgs.writeText "headscale-acls.hujson" ''
                {
                  "acls": [
                    {
                      "action": "accept",
                      "src": [ "*" ],
                      "dst": [ "*:*" ]
                    }
                  ],
                  "ssh": [
                    {
                      "action": "check",
                      "src": [ "autogroup:members" ],
                      "dst": [ "autogroup:self" ],
                      "users": [ "autogroup:nonroot", "root" ],
                    }
                  ]
                }
              '';
            in
            {
              mode = "file"; # Default: 'file' (Options: 'database')
              # The path to a HuJSON file that contains ACL policies.
              # Needed only when the mode option is set to 'file'.
              path = aclsHuJson;
            };
          prefixes = {
            # Specify the strategy applied for allocation of IPs to nodes.
            # 'sequential': assigns the next free IP from the previous given IP.
            # 'random': assigns the next free IP from a pseudo-random IP generator (crypto/rand).
            allocation = "sequential"; # Default: 'sequential' (Options: 'random')
            v4 = "100.64.0.0/10"; # Default: '100.64.0.0/10'
            v6 = "fd7a:115c:a1e0::/48"; # Default: 'fd7a:115c:a1e0::/48'
          };
          # Since Caddy will handle the HTTPS frontend, we don't need Headscale's
          # native TLS and Let's Encrypt configurations.
          # e.g., `tls_cert_path`, `tls_key_path`, `tls_letsencrypt_hostname`, etc.
        };
      };

      yakumo.services.metadata.headscale.reverseProxy = {
        caddyIntegration.enable = true;
      };
    }
  ]);
}
