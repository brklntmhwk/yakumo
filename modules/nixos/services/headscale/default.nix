# WIP
{
  config,
  lib,
  pkgs,
  rootPath,
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
              # Specify the maximum number of WAL file frames before the WAL file
              # is automatically checkpointed.
              # Set to 0 to disable automatic checkpointing.
              wal_autocheckpoint = 1000;
            };
          };
          # DERP (Designated Encrypted Relay for Packets):
          # Tailscale fallback protocol used when direct peer-to-peer connection
          # fails due to strict firewalls, NATs, or missing IPv6.
          # It acts as an encrypted relay for WireGuard packets over HTTPS.
          # https://tailscale.com/blog/how-tailscale-works/#encrypted-tcp-relays-derp
          derp = {
            server = {
              # Use the public Tailscale DERP server instead of spinning up
              # a custom embedded DERP server.
              enabled = false;
            };
            auto_update_enabled = true;
            # Locally available DERP map files encoded in YAML.
            # This is mainly geared toward self-hosted DERP servers.
            # paths = [ ];
            # Specify how often checks for DERP updates are performed.
            update_frequency = "24h"; # Default: '24h'
            # List of externally available DERP maps encoded in JSON.
            urls = [
              # The public Tailscale servers
              "https://controlplane.tailscale.com/derpmap/default"
            ];
          };
          # DNS (Domain Name System)
          dns = {
            # Define the base domain to create the hostnames for MagicDNS.
            base_domain = meta.domain;
            magic_dns = true; # Default: 'true'
            nameservers.global = config.networking.nameservers;
            # Inject these search domains to Tailscale clients.
            # With MagicDNS enabled, our tailnet base_domain is always
            # the first search domain.
            search_domains = [ "yakumo.internal" ];
          };
          # Time before deletion of an inactive ephemeral node.
          ephemeral_node_inactivity_timeout = "30m"; # Default: '30m'
          log = {
            format = "text"; # Default: 'text' (Options: 'json')
            # Options: 'debug', 'error', 'fatal', 'trace', 'panic', 'warn'
            level = "info"; # Default: 'info'
          };
          # TS2021 Noise Protocol
          # Specify the Noise private key to encrypt the traffic between Headscale
          # and Tailscale clients.
          noise.private_key_path = "/var/lib/headscale/noise_private.key";
          # OIDC (OpenID Connect)
          oidc = mkMerge [
            {
              allowed_domains = [ ];
              allowed_users = [ ];
              extra_params = { };
              # PKCE (Proof Key for Code Exchange): Adds an additional security layer
              # to the OAuth 2.0 authorization code flow by preventing authorization
              # code interception attacks.
              # https://datatracker.ietf.org/doc/html/rfc7636
              pkce = {
                enabled = true; # Default: false
                # Use SHA256 hashed code verifier.
                method = "S256"; # Default: 'S256' (Options: 'plain')
              };
              # Specify the scopes obtained from the IdP (e.g., Kanidm).
              # Make them align with the defaults the IdP defines.
              scope = [
                # Ensure to always include the "openid" scope (required).
                # Default: "openid", "profile", and "email"
                "openid"
                "profile"
                "email"
              ];
            }
            (mkIf kaniCfg.enable (
              let
                kanidmCfg = config.yakumo.services.kanidm;
                kaniMeta = config.yakumo.services.metadata.kanidm;
              in
              {
                # Kanidm's specific OIDC issuer URL format requires appending the client ID.
                # Format: https://<kanidm_origin>/oauth2/openid/<kanidm_system_name>
                issuer = "https://${kaniMeta.domain}/oauth2/openid/headscale"; # Default: ''
                client_id = "headscale"; # Default: ''
                client_secret_path = config.sops.secrets."kanidm/headscale_oidc_client_secret".path; # Default: null
              }
            ))
          ];
          # ACLs (Access Control Lists)
          # https://tailscale.com/kb/1018/acls/
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

      sops.secrets = {
        headscale_oidc_secret = {
          sopsFile = rootPath + "/secrets/default.yaml";
          owner = "headscale";
        };
      };
    }
  ]);
}
