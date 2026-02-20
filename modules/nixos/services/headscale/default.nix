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
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.services.headscale;
in
{
  options.yakumo.services.headscale = {
    enable = mkEnableOption "headscale";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.headscale = {
        enable = true;
        address = "0.0.0.0"; # Default: '127.0.0.1'
        group = "headscale"; # Default: 'headscale'
        port = "8080"; # Default: '8080'
        user = "headscale"; # Default: 'headscale'
        settings = {
          server_url = "https://headscale.yakumo.net";
          database = {
            type = "postgres"; # Default: 'sqlite' (Options: 'postgres', 'sqlite3')
            postgres = {
              name = "headscale";
              host = "127.0.0.1";
              user = "headscale";
              port = "3306";
              password_file = config.sops.secrets.xxx.path;
            };
          };
          # DERP (Designated Encrypted Relay for Packets):
          derp = {
            auto_update_enabled = true;
            paths = [ ];
            update_frequency = "24h"; # Default: '24h'
            urls = [ ];
            server.private_key_path = "/path/to/derp-server-private.key";
          };
          # DNS (Domain Name System):
          dns = {
            base_domain = "yakumo.internal";
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
    }
  ]);
}
