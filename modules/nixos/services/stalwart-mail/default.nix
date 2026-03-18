# WIP
{
  config,
  lib,
  flakeRoot,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.stalwart-mail;
  meta = config.yakumo.services.metadata.stalwart-mail;
in
{
  options.yakumo.services.stalwart-mail = {
    enable = mkEnableOption "stalwart-mail";
  };

  config = mkIf cfg.enable (
    let
      stalwartCfg = config.services.stalwart-mail;
    in
    mkMerge [
      {
        services.stalwart-mail = {
          enable = true;
          # Leave this disabled and manually add ports to
          # `networking.firewall.allowedTCPPorts` on an as-needed basis.
          openFirewall = false; # Default: false
          dataDir = "/var/lib/stalwart-mail";
          # Set credentials env vars to configure Stalwart-Mail secrets.
          # These secrets can be accessed in configuration values with the macros such as
          # %{file:/run/credentials/stalwart-mail.service/VAR_NAME}%.
          # For the macro syntax, see: https://stalw.art/docs/configuration/macros
          credentials = { };
          # For the available options, see:
          # https://stalw.art/docs/category/configuration/
          settings = {
            # https://stalw.art/docs/auth/authorization/administrator/#fallback-administrator
            authentication.fallback-admin = {
              user = "admin";
              secret = "%{file:/etc/stalwart/admin-pw}%";
            };
            # DKIM (DomainKeys Identified Mail)
            # https://stalw.art/docs/mta/authentication/dkim/sign
            auth.dkim.sign = [
              {
                "if" = "is_local_domain('*', sender_domain)";
                "then" = "['ed25519-' + sender_domain]";
              }
              { "else" = false; }
            ];
            # https://stalw.art/docs/server/tls/certificates/
            certificate.default =
              let
                acmeCerts = config.security.acme.certs;
              in
              {
                # Specify this certificate as the default for the situation where
                # the client doesn't provide an SNI server name.
                default = true;
                cert = "%{file:${acmeCerts.${meta.domain}.directory}/fullchain.pem}%";
                private-key = "%{file:${acmeCerts.${meta.domain}.directory}/key.pem}%";
              };
            # https://stalw.art/docs/mta/authentication/dkim/sign#signatures
            signature =
              let
                inherit (meta) domain;
              in
              {
                "ed25519-${domain}" = {
                  inherit domain;
                  private-key = "%{file:/var/lib/stalwart-mail/dkim/ed25519-${domain}.key}%";
                  algorithm = "ed25519-sha256";
                  canonicalization = "relaxed/relaxed";
                  headers = [
                    "From"
                    "To"
                    "Date"
                    "Subject"
                    "Message-ID"
                  ];
                  selector = "ed-default";
                  set-body-length = false;
                  report = true;
                };
              };
            # https://stalw.art/docs/category/server-settings
            server = {
              hostname = cfg.domain;
              tls = {
                enable = true;
                certificate = "default";
                # Set this per listener.
                # implicit = true;
              };
              listener = {
                # SMTP: Used for receiving email from other mail servers (Essential).
                smtp = {
                  bind = "[::]:25";
                  protocol = "smtp";
                };
                # SMTPS (SMTP over TLS/SSL): Handles email submission with implicit
                # TLS encryption (Essential).
                # Used for securely sending outgoing mail from user clients.
                submissions = {
                  bind = "[::]:465";
                  protocol = "smtp";
                  tls.implicit = true;
                };
                # IMAPS (IMAP over SSL/TLS): Handles IMAP over implicit TLS (Essential).
                # Required for secure email access via IMAP clients.
                imaps = {
                  bind = "[::]:993";
                  protocol = "imap";
                  tls.implicit = true;
                };
                # JMAP (JSON Meta Application Protocol): A modern, efficient, and
                # stateful protocol for synchronizing mail, calendars, and contacts
                # between a client and a server.
                # It operates over HTTP and uses JSON as its data format.
                # As an http listener is automatically created in the installation
                # process and Stalwart enables JMAP by default with the http listener
                # configured, we don't have to manually add this.
                # https://stalw.art/docs/http/jmap/overview
                # jmap = {
                #   bind = "[::]:8080";
                #   protocol = "http";
                #   tls.implicit = true;
                # };
                # HTTP: Handles JMAP access, WebDAV access, API management, ACME
                # certificate issuance, autoconfig/autodiscover protocols,
                # well-known resources, metrics collection, and OAuth authentication.
                # We leave the external HTTPS traffic handling job to a reverse proxy
                # here instead of having Stalwart-Mail handle it directly on Port 443.
                http = {
                  bind = "[::]:8080";
                  protocol = "http";
                  url = "https://${cfg.domain}";
                  # Set this to true only when Stalwart is behind a trusted proxy;
                  # it obtains the client's IP address from the `Forwarded` or
                  # `X-Forwarded-For` HTTP header rather than from the socket source
                  # address. That is, untrusted sources can easily forge these headers,
                  # potentially leading to security vulnerabilities or incorrect login
                  # information.
                  use-x-forwarded = true;
                };
                # ManageSieve: A protocol designed for remotely managing Sieve scripts
                # on a mail server.
                # https://stalw.art/docs/sieve/managesieve/
                sieve = {
                  protocol = "managesieve";
                  bind = "[::]:4190";
                  tls.implicit = true;
                };
              };
            };
            # https://stalw.art/docs/storage/backends/sqlite
            store.db = {
              type = "sqlite";
              path = "${stalwartCfg.dataDir}/database.sqlite3";
            };
            # https://stalw.art/docs/mta/outbound/dns/
            resolver = {
              # Options: 'cloudflare', 'cloudflare-tls', 'quad9', 'quad9-tls', 'google', 'custom'
              type = "system";
            };
          };
        };

        users.groups.acme.members = [ "stalwart-mail" ];

        networking.firewall.allowedTCPPorts = [
          25 # SMTP
          465 # SMTPS (SMTP TLS)
          993 # IMAPS (IMAP TLS)
          4190 # ManageSieve
        ];

        yakumo =
          let
            rusticCfg = config.yakumo.services.rustic;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata = {
                # TODO: Revisit this Caddy configuration.
                # https://stalw.art/docs/server/reverse-proxy/caddy
                stalwart-mail.reverseProxy = {
                  caddyIntegration.enable = true;
                };
              };
            }
            (mkIf rusticCfg.enable {
              services.rustic.backups = {
                stalwart = {
                  environmentFile = config.sops.secrets.rustic_stalwart_env.path;
                  timerConfig = {
                    OnCalendar = "*-*-* 03:00:00"; # Run daily at 3 a.m.
                    Persistent = true;
                  };
                  settings = {
                    repository = "s3:https://your-s3-endpoint/bucket/stalwart-mail";
                    backup = {
                      sources = [ stalwartCfg.dataDir ];
                    };
                    forget = {
                      keep-daily = 7;
                      keep-weekly = 4;
                      keep-monthly = 6;
                      prune = true;
                    };
                  };
                };
              };
            })
            (mkIf yosugaCfg.enable {
              system.persistence.yosuga = {
                directories = [
                  {
                    path = stalwartCfg.dataDir;
                    user = "stalwart-mail";
                    group = "stalwart-mail";
                    mode = "0700";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          rustic_stalwart_env = {
            sopsFile = flakeRoot + "/secrets/default.yaml";
          };
        };
      }
    ]
  );
}
