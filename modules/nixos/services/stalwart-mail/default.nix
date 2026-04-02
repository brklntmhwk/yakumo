# WIP
# Based on:
# https://github.com/oddlama/nix-config/blob/1d62249db4a0f68dcdf99c890542540ad0dcefd5/hosts/envoy/stalwart-mail.nix
{
  config,
  lib,
  pkgs,
  rootPath,
  yakumoMeta,
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
      inherit (meta) domain port extraPorts;
      stalwartCfg = config.services.stalwart-mail;
    in
    mkMerge [
      {
        assertions = [
          {
            assertion = cfg.enable -> config.yakumo.security.acme.enable;
            message = "ACME must be enabled if using Stalwart-Mail";
          }
        ];

        services.stalwart-mail = {
          enable = true;
          # Leave this disabled and manually add ports to
          # `networking.firewall.allowedTCPPorts` on an as-needed basis.
          openFirewall = false; # Default: false
          dataDir = "/var/lib/stalwart-mail";
          # Set credentials env vars to configure Stalwart-Mail secrets.
          # These secrets can be accessed in configuration values with the macros such as
          # %{file:/run/credentials/stalwart-mail.service/VAR_NAME}%.
          # The value(s) given will be set for the `LoadCredential` systemd setting.
          # For the macro syntax, see: https://stalw.art/docs/configuration/macros
          credentials = {
            user_admin_password = config.sops.secrets."stalwart/admin_passwd".path;
          };
          # For the available options, see:
          # https://stalw.art/docs/category/configuration/
          settings = {
            # Add settings that Stalwart-Mail should only read from the local configuration
            # file (i.e., this Nix file) and never from its internal DB, which reflects
            # changes made dynamically via its web admin UI.
            # https://stalw.art/docs/configuration/overview/#local-and-database-settings
            config.local-keys = [
              # Defaults
              "store.*"
              "directory.*"
              "tracer.*"
              "!server.blocked-ip.*"
              "!server.allowed-ip.*"
              "server.*"
              "authentication.fallback-admin.*"
              "cluster.*"
              "config.local-keys.*"
              "storage.data"
              "storage.blob"
              "storage.lookup"
              "storage.fts"
              "storage.directory"
              "certificate.*"
              # Customs
              "auth.dkim.*"
              "signature.*"
              "resolver.*"
              "spam-filter.resource"
              "web-admin.path"
              "web-admin.resource"
            ];
            # https://stalw.art/docs/auth/authorization/administrator/#fallback-administrator
            authentication.fallback-admin = {
              user = "admin";
              secret = "%{file:/run/credentials/stalwart-mail.service/stalwart/admin_passwd}%";
            };
            # DKIM (DomainKeys Identified Mail)
            # https://stalw.art/docs/mta/authentication/dkim/sign
            auth.dkim.sign = [
              {
                # Check if the person sending the email is doing so from a domain
                # that is actively hosted on this server.
                "if" = "is_local_domain('*', sender_domain)";
                # If true, sign the email as shown below.
                "then" = "['rsa-' + sender_domain, 'ed25519-' + sender_domain]";
              }
              # Don't sign it otherwise.
              { "else" = false; }
            ];
            # https://stalw.art/docs/server/tls/certificates/
            certificate.default =
              let
                acmeCertsDir = config.security.acme.certs.${domain}.directory;
              in
              {
                # Specify this certificate as the default for the situation where
                # the client doesn't provide an SNI (Server Name Indication) server name.
                default = true;
                cert = "%{file:${acmeCertsDir}/fullchain.pem}%";
                private-key = "%{file:${acmeCertsDir}/key.pem}%";
              };
            # Generate the RSA signing key (legacy) for DKIM as well as the ED25519 one
            # for backward compatibility; some legacy enterprise firewalls and
            # rigid institutional spam filters still don't know how to read ED25519.
            #
            # https://stalw.art/docs/mta/authentication/dkim/sign#signatures
            signature = {
              "rsa-${domain}" = {
                inherit domain;
                private-key = "%{file:/var/lib/stalwart-mail/dkim/rsa-${domain}.key}%";
                algorithm = "rsa-sha256";
                canonicalization = "relaxed/relaxed";
                headers = [
                  "From"
                  "To"
                  "Date"
                  "Subject"
                  "Message-ID"
                ];
                selector = "rsa_default";
                set-body-length = false;
                report = true;
              };
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
                selector = "ed_default";
                set-body-length = false;
                report = true;
              };
            };
            # https://stalw.art/docs/category/server-settings
            server = {
              hostname = cfg.domain;
              # https://stalw.art/docs/category/tls
              tls = {
                enable = true;
                certificate = "default";
                # Specify the amount of time the listener should wait for a client
                # to initiate the TLS handshake before timing out the connection.
                timeout = "1m";
                # Let the listener ignore the order of the ciphers presented by
                # the client.
                ignore-client-order = true;
                # Set this on a per-listener basis below.
                # implicit = true;
              };
              listener = {
                # SMTP: Used for receiving email from other mail servers (Essential).
                smtp = {
                  bind = "[::]:${extraPorts.smtp}";
                  protocol = "smtp";
                };
                # SMTPS (SMTP over TLS/SSL): Handles email submission with implicit
                # TLS encryption (Essential).
                # Used for securely sending outgoing mail from user clients.
                submissions = {
                  bind = "[::]:${extraPorts.submissions}";
                  protocol = "smtp";
                  tls.implicit = true;
                };
                # IMAPS (IMAP over SSL/TLS): Handles IMAP over implicit TLS (Essential).
                # Required for secure email access via IMAP clients.
                imaps = {
                  bind = "[::]:${extraPorts.imaps}";
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
                #   bind = "[::]:${port}";
                #   protocol = "http";
                #   tls.implicit = true;
                # };
                # HTTP: Handles JMAP access, WebDAV access, API management, ACME
                # certificate issuance, autoconfig/autodiscover protocols,
                # well-known resources, metrics collection, and OAuth authentication.
                # We leave the external HTTPS traffic handling job to a reverse proxy
                # here, instead of having Stalwart-Mail handle it directly on Port 443.
                # By doing so, a reverse proxy can centrally manage
                # Let's Encrypt (ACME) and overall certificate renewals.
                http = {
                  bind = "[::]:${port}";
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
                  bind = "[::]:${extraPorts.sieve}";
                  protocol = "managesieve";
                  tls.implicit = true;
                };
              };
            };
            # Although the upstream NixOS module takes care of this DB configuration
            # automatically, we prefer to explicitly configure it.
            # Apparently, if the value of `system.stateVersion` is older than '24.11',
            # it defaults to SQLite, otherwise to RocksDB.
            # https://stalw.art/docs/storage/backends/rocksdb/
            store.db = {
              type = "rocksdb";
              path = "${stalwartCfg.dataDir}/db";
              # LZ4 is a lossless data compression algorithm optimized for fast
              # compression/decompression.
              # https://stalw.art/docs/storage/blob/#compression
              compression = "lz4";
            };
            # https://stalw.art/docs/mta/outbound/dns/
            resolver = {
              # Options: 'cloudflare', 'cloudflare-tls', 'quad9', 'quad9-tls', 'google', 'custom', 'system'
              type = "system"; # Use the system's default DNS resolver.
              # The maximum number of concurrent resolution requests made.
              concurrency = 2;
              # The time window to timeout when no response is received.
              timeout = "10s";
              # The maximum number of resolution request attempts before regarded
              # as failure.
              attempts = 3;
              # Whether to preserve the intermediate name servers in the DNS
              # resolution results.
              preserve-intermediates = true;
              # Whether to try using TCP for resolution requests if an error occurs
              # during a UDP resolution request.
              try-tcp-on-error = true;
              # Whether to use EDNS (Extension mechanisms for DNS) for resolution
              # requests. This is required for some DNS features (e.g., DNSSEC).
              edns = true;
            };
            # https://stalw.art/docs/mta/reports/analysis
            report.analysis = {
              # A list of addresses from which reports will be intercepted and analyzed.
              addresses = [
                "abuse@*"
                "dmarc@*"
                "noreply-dmarc-support@*"
                "noreply-smtp-tls-reporting@*"
                "postmaster@*"
              ];
              # Whether reports should be forwarded to their final recipient
              # after analysis.
              forward = false;
              # The duration for which reports should be stored before deletion.
              # Set this to false to disable storage.
              store = "30d";
            };
            # https://stalw.art/docs/email/imap/#folders
            email.folders = {
              archive = {
                name = "Archive";
                create = true; # Whether to create the folder if it doesn't exist.
                subscribe = true; # Whether to subscribe to the folder by default.
              };
            };
          };
        };

        # Add the stalwart-mail user to the acme group, granting it the right to
        # read the `fullchain.pem` and `key.pem` files directly from '/var/lib/acme/'
        # without needing to copy or duplicate the sensitive files.
        users.groups.acme.members = [ "stalwart-mail" ];

        networking.firewall.allowedTCPPorts = [
          25 # SMTP
          465 # SMTPS (SMTP TLS)
          993 # IMAPS (IMAP TLS)
          4190 # ManageSieve
        ];

        systemd.services.stalwart-mail =
          let
            inherit (lib) getExe mkAfter;
          in
          {
            # https://stalw.art/docs/mta/authentication/dkim/sign#generating-keys
            preStart = mkAfter ''
              mkdir -p /var/lib/stalwart-mail/dkim

              if [[ ! -e /var/lib/stalwart-mail/dkim/rsa-${domain}.key ]]; then
                echo "Generating RSA DKIM key for ${domain}"
                ${getExe pkgs.openssl} genrsa -traditional -out /var/lib/stalwart-mail/dkim/rsa-${domain}.key 2048
              fi
              if [[ ! -e /var/lib/stalwart-mail/dkim/ed25519-${domain}.key ]]; then
                echo "Generating ED25519 DKIM key for ${domain}"
                ${getExe pkgs.openssl} genpkey -algorithm ed25519 -out /var/lib/stalwart-mail/dkim/ed25519-${domain}.key
              fi
            '';
          };

        yakumo =
          let
            inherit (lib) elem;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata = {
                # https://stalw.art/docs/server/reverse-proxy/caddy
                stalwart-mail.reverseProxy = {
                  caddyIntegration = {
                    enable = true;
                    acme.enable = true;
                    serverAliases = [
                      "${domain}"
                      # MTA-STS (Mail Transfer Agent Strict Transport Security):
                      # A security mechanism for email systems to protect against
                      # eavesdropping and tampering of emails during transmission.
                      # https://stalw.art/docs/mta/transport-security/mta-sts/
                      "mta-sts.${domain}"
                      # Autoconfig and Autodiscover: Protocols designed to simplify
                      # the configuration of email clients by automatically providing
                      # them with the necessary server settings.
                      # https://stalw.art/docs/server/autoconfig/
                      "autoconfig.${domain}"
                      "autodiscover.${domain}"
                    ];
                  };
                };
              };
            }
            (mkIf (elem "rustic" yakumoMeta.allServices) {
              services.rustic.backups = {
                stalwart = {
                  environmentFile = config.sops.secrets."stalwart/rustic_env_file".path;
                  timerConfig = {
                    OnCalendar = "*-*-* 03:00:00"; # Run daily at 3 a.m.
                    Persistent = true;
                  };
                  settings = {
                    repository = {
                      repository = "s3:https://your-s3-endpoint/bucket/stalwart-mail";
                    };
                    backup = {
                      snapshots = [
                        {
                          name = "stalwart-mail";
                          sources = [ stalwartCfg.dataDir ];
                        }
                      ];
                    };
                    forget = {
                      keep-hourly = 48;
                      keep-daily = 14;
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
          "stalwart/admin_passwd" = {
            sopsFile = rootPath + "/secrets/default.yaml";
          };
          "stalwart/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
          };
        };
      }
    ]
  );
}
