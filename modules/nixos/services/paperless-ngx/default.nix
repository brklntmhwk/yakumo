# WIP
# Based on:
# https://github.com/oddlama/nix-config/blob/8a56a60e58205bc249e12af2276a9eb1daea583f/hosts/sire/guests/paperless.nix
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
    mkBefore
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.paperless-ngx;
  meta = config.yakumo.services.metadata.paperless-ngx;
in
{
  options.yakumo.services.paperless-ngx = {
    enable = mkEnableOption "paperless-ngx";
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) toJSON;
      inherit (lib) elem;
      paperlessCfg = config.services.paperless;
    in
    mkMerge [
      {
        services.paperless = {
          inherit (meta)
            address # Default: '127.0.0.1'
            domain # Default: null
            port # Default: 28981
            ;
          enable = true;
          user = "paperless"; # Default: 'paperless'
          environmentFile = config.sops.secrets."paperless/env_file".path; # Default: null
          passwordFile = config.sops.secrets."paperless/passwd_file".path;
          consumptionDir = "${paperlessCfg.dataDir}/consume";
          # Allow all users can write to the consumption directory if set to true.
          consumptionDirIsPublic = false; # Default: false
          dataDir = "/var/lib/paperless"; # Default: '/var/lib/paperless'
          # This is where actual PDF files are stored.
          mediaDir = "${paperlessCfg.dataDir}/media";
          # Configure local PostgreSQL DB server. Enabling this automatically does:
          # - Configure `ensureDatabases` & `ensureUsers` in `services.postgresql`
          # for Paperless-ngx.
          database.createLocally = true; # Default: false
          # TODO: Consider implementing and using a systemd backup service & Rustic for backups instead.
          # Configure the document exporter.
          # For more details, see:
          # https://docs.paperless-ngx.com/administration/#exporter
          exporter = {
            enable = true; # Default: false
            directory = "${paperlessCfg.dataDir}/export";
            # Schedule when to run the exporter.
            onCalendar = "02:00:00";
            settings = {
              compare-checksums = true;
              delete = true;
              no-color = true;
              no-progress-bar = true;
            };
          };
          settings =
            let
              inherit (lib) concatStringsSep;
              inherit (meta) domain;
            in
            {
              # The upstream sets this to "https://${config.services.paperless.domain}".
              # PAPERLESS_URL = "https://${domain}";

              PAPERLESS_ALLOWED_HOSTS = domain;
              PAPERLESS_CORS_ALLOWED_HOSTS = "https://${domain}";
              # TODO: Set a proper proxies.
              PAPERLESS_TRUSTED_PROXIES = concatStringsSep "," [ ];
              # Have your proxy handle this, which is likely more efficient.
              PAPERLESS_ENABLE_COMPRESSION = false;
              # Paperless-ngx uses OCRmyPDF as the OCR backend.
              # For the valid configuration options, see:
              # https://ocrmypdf.readthedocs.io/en/latest/apiref.html
              PAPERLESS_OCR_USER_ARGS = toJSON {
                continue_on_soft_render_error = true;
                # https://ocrmypdf.readthedocs.io/en/latest/cookbook.html#digitally-signed-pdfs
                invalidate_digital_signatures = true;
                optimize = 1;
              };
              # Paperless-ngx comes with these languages by default:
              # - English, German, Italian, Spanish, and French
              # For the valid lang code, see:
              # https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html
              PAPERLESS_OCR_LANGUAGE = concatStringsSep "+" [
                "eng" # English
                "jpn" # Japanese
                "spa" # Spanish
              ];
              # Add non-default langs here (as a space-separated string) to enable them.
              PAPERLESS_OCR_LANGUAGES = concatStringsSep " " [
                "jpn" # Japanese
              ];
              # Enable polling and set its interval in seconds.
              PAPERLESS_CONSUMER_POLLING = 3;
              # Set the maximum number of times the file modification check is done.
              # If a file's modification time and size are identical for two consecutive
              # checks, it'll be consumed.
              PAPERLESS_CONSUMER_POLLING_DELAY = 5;
              # Set the delay in seconds between each check done while waiting for
              # a single file to remain unmodified.
              PAPERLESS_CONSUMER_POLLING_DELAY = 3;
              PAPERLESS_CONSUMER_ENABLE_BARCODES = true;
              PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
              PAPERLESS_CONSUMER_BARCODE_SCANNER = "PYZBAR"; # Default: "PYZBAR" (Options: 'ZXING')
              PAPERLESS_CONSUMER_RECURSIVE = true;
              # For the valid filename format, see:
              # https://docs.paperless-ngx.com/advanced_usage/#file-name-handling
              PAPERLESS_FILENAME_FORMAT = "{{ owner_username }}/{{ created_year }}-{{ created_month }}-{{ created_day }}_{{ asn }}_{{ title }}";
              # Specify how many things Paperless-ngx will do in parallel.
              # e.g., Manage the search index, check emails, consume documents, etc.
              PAPERLESS_TASK_WORKERS = 3;
              # Specify how many pages Paperless-ngx will process in parallel
              # on a single document.
              # NOTE: Ensure that the product of the following doesn't exceed your CPU
              # core count, or it'll be extremely slow.
              # `PAPERLESS_TASK_WORKERS * PAPERLESS_THREADS_PER_WORKER`
              PAPERLESS_THREADS_PER_WORKER = 2;
              # Specify the number of worker processes the web server should spawn.
              PAPERLESS_WEBSERVER_WORKERS = 3;
            };
          # Enable a workaround for document classifier timeouts.
          # This sets `OMP_NUM_THREADS` to 1.
          # For the detail, see: https://github.com/NixOS/nixpkgs/issues/240591
          openMPThreadingWorkaround = true; # Default: true
        };

        yakumo =
          let
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata = {
                paperless-ngx.reverseProxy = {
                  caddyIntegration.enable = true;
                };
              };
            }
            (mkIf (elem "rustic" yakumoMeta.allServices) {
              services.rustic.backups = {
                paperless = {
                  environmentFile = config.sops.secrets."paperless/rustic_env_file".path;
                  timerConfig = {
                    OnCalendar = "*-*-* 02:45:00"; # Run daily at 2:45 a.m.
                    Persistent = true;
                  };
                  settings = {
                    repository = {
                      repository = "s3:https://your-s3-endpoint/bucket/paperless";
                    };
                    backup = {
                      snapshots = [
                        {
                          name = "paperless";
                          sources = [
                            paperlessCfg.exporter.directory
                          ];
                        }
                      ];
                    };
                    forget = {
                      keep-daily = 7;
                      keep-weekly = 4;
                      keep-monthly = 12;
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
                    path = paperlessCfg.dataDir;
                    user = "paperless";
                    group = "paperless";
                    mode = "0750";
                  }
                  {
                    path = paperlessCfg.exporter.directory;
                    user = "paperless";
                    group = "paperless";
                    mode = "0750";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          "paperless/env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "paperless";
          };
          "paperless/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "paperless";
          };
          "paperless/passwd_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "paperless";
          };
        };
      }
      (mkIf (elem "kanidm" yakumoMeta.allServices) {
        services.paperless.settings = {
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          # This is used for login and signup setups via social account providers
          # that are compatible with django-allauth.
          # For the valid configuration, see:
          # https://docs.allauth.org/en/latest/socialaccount/providers/openid_connect.html
          PAPERLESS_SOCIALACCOUNT_PROVIDERS =
            let
              kaniMeta = config.yakumo.services.metadata.kanidm;
            in
            toJSON {
              openid_connect = {
                OAUTH_PKCE_ENABLED = "True";
                APPS = [
                  rec {
                    provider_id = "kanidm";
                    name = "Kanidm";
                    client_id = "paperless";
                    # This will be added in `systemd.services.paperless-web.script` dynamically.
                    # secret = "";
                    settings.server_url = "https://${kaniMeta.domain}/oauth2/openid/${client_id}/.well-known/openid-configuration";
                  }
                ];
              };
            };
        };

        # Add secret to PAPERLESS_SOCIALACCOUNT_PROVIDERS.
        systemd.services.paperless-web.script = mkBefore ''
          oidcSecret=$(< ${config.sops.secrets."kanidm/paperless-ngx_oauth2_client_secret".path})
          export PAPERLESS_SOCIALACCOUNT_PROVIDERS=$(
            ${pkgs.jq}/bin/jq <<< "$PAPERLESS_SOCIALACCOUNT_PROVIDERS" \
              --compact-output \
              --arg oidcSecret "$oidcSecret" '.openid_connect.APPS.[0].secret = $oidcSecret'
          )
        '';
      })
    ]
  );
}
