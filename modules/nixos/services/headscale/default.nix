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
          database =
            let
              pgSrvMetadata = config.yakumo.services.metadata.postgresql;
            in
            {
              type = "postgres"; # Default: 'sqlite' (Options: 'postgres', 'sqlite3')
              postgres = {
                inherit (pgSrvMetadata) port;
                name = "headscale";
                user = "headscale";
                host = pgSrvMetadata.address;
                password_file = config.sops.secrets.xxx.path;
              };
            };
          # DERP (Designated Encrypted Relay for Packets):
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
          # DNS (Domain Name System):
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
          # OIDC (OpenID Connect):
          oidc = {
            allowed_domains = [ ];
            allowed_users = [ ];
            client_secret_path = config.sops.secrets.headscale.path;
            client_id = "Headscale";
            extra_params = { };
            issuer = "https://";
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
          # ACLs (Access Control Lists):
          policy = {
            mode = "file"; # Default: 'file' (Options: 'database')
            # The path to a HuJSON file that contains ACL policies.
            # Needed only when the mode option is set to 'file'.
            path = "/path/to/acls-file";
          };
          prefixes = {
            allocation = "sequential"; # Default: 'sequential' (Options: 'random')
            v4 = "100.64.0.0/10";
            v6 = "fd7a:115c:a1e0::/48";
          };
          tls_cert_path = "path/to/tls_cert_path";
          tls_key_path = "path/to/tls_key_path";
          # Domain name to request a TLS certificate for.
          tls_letsencrypt_hostname = "headscale";
          tls_letsencrypt_challenge_type = "HTTP-01"; # Default: 'HTTP-01' (Options: 'TLS-ALPN-01')
          tls_letsencrypt_listen = ":http"; # Default: ':http'
        };
      };

      services.caddy.virtualHosts = {
        # https://headscale.net/stable/ref/integration/reverse-proxy/#caddy
        "${meta.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${meta.bindAddress}
          '';
        };
      };
    }
  ];
}
