{
  config,
  lib,
  rootPath,
  rootMeta,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.yakumo.security.acme;
in
{
  options.yakumo.security.acme = {
    enable = mkEnableOption "acme";
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) optional;
      inherit (rootMeta.network) base_domain dns_provider internal_domain;
      inherit (rootMeta.security) acme_email;
      yosugaCfg = config.yakumo.system.persistence.yosuga;
      caddyCfg = config.yakumo.services.caddy;
      stalwartCfg = config.yakumo.services.stalwart-mail;
    in
    mkMerge [
      {
        security.acme = {
          # Accept the Certificate Authority's (e.g., Let's Encrypt) Terms of Service.
          # This is necessary to use ACME.
          acceptTerms = true;
          defaults = {
            # Enable DNS propagation check. It verifies whether changes to our domain's
            # DNS records—such as updating an IP address, switching hosting providers,
            # or modifying email settings—have been successfully updated across the
            # global network of DNS servers.
            dnsPropagationCheck = true; # Default: true
            # Set this to our email address for account creation and correspondence
            # from the Certificate Authority.
            # Recommended to use the same email for all certs to avoid account creation
            # limits.
            email = rootMeta.security.acme_email; # Default: null
            # Specify which group to run the ACME client (LEGO).
            group = "acme"; # Default: 'acme'
            # Specify systemd services to call `systemctl try-reload-or-restart` on.
            reloadServices =
              [ ] ++ optional caddyCfg.enable "caddy" ++ optional stalwartCfg.enable "stalwart-mail";
          };
          certs = {
            # These keys will automatically be the value of the `domain` option.
            "${base_domain}" = {
              extraDomainNames = [
                "*.${base_domain}"
              ]; # Default: [ ]
            };
            "${internal_domain}" = {
              extraDomainNames = [
                "*.${internal_domain}"
              ]; # Default: [ ]
            };
          };
        };
      }
      (mkIf (dns_provider == "cloudflare") {
        security.acme = {
          defaults = {
            # For the valid provider list, see:
            # https://go-acme.github.io/lego/dns/
            dnsProvider = dns_provider; # Default: null
            credentialFiles = {
              # API token with DNS:Edit permission (since v3.1.0).
              CF_DNS_API_TOKEN_FILE = config.sops.secrets."acme/cf_dns_token".path;
              # API token with Zone:Read permission (since v3.1.0).
              CF_ZONE_API_TOKEN_FILE = config.sops.secrets."acme/cf_zone_token".path;
            };
          };
        };

        sops.secrets = {
          "acme/cf_dns_token" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            mode = "0440";
            group = "acme";
          };
          "acme/cf_zone_token" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            mode = "0440";
            group = "acme";
          };
        };
      })
      (mkIf yosugaCfg.enable {
        yakumo.system.persistence.yosuga = {
          directories = [
            {
              path = "/var/lib/acme";
              user = "acme";
              group = "acme";
              mode = "0755";
            }
          ];
        };
      })
    ]
  );
}
