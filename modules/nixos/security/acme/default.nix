{
  config,
  lib,
  rootPath,
  yakumoMeta,
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
            credentialFiles = {
              # API token with DNS:Edit permission (since v3.1.0).
              CF_DNS_API_TOKEN_FILE = config.sops.secrets."acme/cf_dns_token".path;
              # API token with Zone:Read permission (since v3.1.0).
              CF_ZONE_API_TOKEN_FILE = config.sops.secrets."acme/cf_zone_token".path;
            };
            # For the valid provider list, see:
            # https://go-acme.github.io/lego/dns/
            dnsProvider = "cloudflare"; # Default: null
            # Enable DNS propagation check. It verifies whether changes to our domain's
            # DNS records—such as updating an IP address, switching hosting providers,
            # or modifying email settings—have been successfully updated across the
            # global network of DNS servers.
            dnsPropagationCheck = true; # Default: true
            # Set this to our email address for account creation and correspondence
            # from the Certificate Authority.
            # Recommended to use the same email for all certs to avoid account creation
            # limits.
            email = yakumoMeta.security.acme_email; # Default: null
            # Specify which group to run the ACME client (LEGO).
            group = "acme"; # Default: 'acme'
            # Specify systemd services to call `systemctl try-reload-or-restart` on.
            reloadServices =
              [ ] ++ optional caddyCfg.enable "caddy" ++ optional stalwartCfg.enable "stalwart-mail";
          };
          certs = {
            # These keys will automatically be the value of the `domain` option.
            "${yakumoMeta.network.base_domain}" = {
              extraDomainNames = [
                "*.${yakumoMeta.network.base_domain}"
              ]; # Default: [ ]
            };
            "${yakumoMeta.network.internal_domain}" = {
              extraDomainNames = [
                "*.${yakumoMeta.network.internal_domain}"
              ]; # Default: [ ]
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
      }
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
      (mkIf caddyCfg.enable {
        # Add the Caddy service user to the global ACME group so Caddy can read
        # every ACME certificate.
        users.groups.acme.members = [ "caddy" ];
      })
    ]
  );
}
