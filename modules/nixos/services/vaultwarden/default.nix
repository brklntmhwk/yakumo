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
    mkForce
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.vaultwarden;
  meta = config.yakumo.services.metadata.vaultwarden;
in
{
  options.yakumo.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable (
    let
      vaultCfg = config.services.vaultwarden;
    in
    mkMerge [
      {
        services.vaultwarden = {
          inherit (meta) domain;
          enable = true;
          backupDir = "/var/backup/vaultwarden"; # Default: null
          environmentFile = config.sops.secrets.vaultwarden_env.path; # Default: [ ]
          # Use Caddy instead.
          configureNginx = false; # Default: false
          configurePostgres = false; # Default: false
          dbBackend = "sqlite"; # Default: 'sqlite' (Options: 'mysql', 'postgresql')
          # For the valid env variables, see:
          # https://github.com/dani-garcia/vaultwarden/blob/1.35.2/.env.template
          config = {
            # The value of DOMAIN will be "https://${services.vaultwarden.domain}".
            ROCKET_ADDRESS = meta.address;
            ROCKET_PORT = meta.port;
            SIGNUPS_ALLOWED = false;
            USE_SYSLOG = true;
            WEB_VAULT_ENABLED = true;
          };
        };

        yakumo =
          let
            rusticCfg = config.yakumo.services.rustic;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            {
              services.metadata = {
                vaultwarden.reverseProxy = {
                  # https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples
                  caddyIntegration = {
                    enable = true;
                    extraConfig = ''
                      # This setting may have compatibility issues with some browsers
                      # (e.g., attachment downloading on Firefox). Try disabling this
                      # if you encounter issues.
                      encode zstd gzip

                      # Security headers
                      header / {
                        # Enable HTTP Strict Transport Security (HSTS).
                        Strict-Transport-Security "max-age=31536000;"
                        # Disable cross-site filter (XSS).
                        X-XSS-Protection "0"
                        # Set this to "SAMEORIGIN", otherwise the browser will block those
                        # requests if using FIDO2 WebAuthn.
                        X-Frame-Options "SAMEORIGIN"
                        # Prevent search engines from indexing.
                        X-Robots-Tag "noindex, nofollow"
                        # Disallow sniffing of X-Content-Type-Options.
                        X-Content-Type-Options "nosniff"
                        # Server name removing.
                        -Server
                        # Remove X-Powered-By though this shouldn't be an issue,
                        # better opsec to remove.
                        -X-Powered-By
                        # Remove Last-Modified because etag is the same and is as effective.
                        -Last-Modified
                      }

                      # Restrict the /admin panel to trusted networks.
                      @admin {
                        path /admin*
                        # Explicitly include 100.64.0.0/10 alongside standard RFC1918 private IPs.
                        not remote_ip private_ranges 100.64.0.0/10
                      }
                      # Simply throw a 403 error instead of redirecting unauthorized `/admin`
                      # attempts back to the homepage, which makes monitoring logs for malicious
                      # access attempts much easier.
                      respond @admin "403 Forbidden" 403

                      # Proxy traffic to the local Rocket server.
                      reverse_proxy ${meta.bindAddress} {
                        # Send the true remote IP to Rocket, so that Vaultwarden can put this
                        # in the log, so that fail2ban can ban the correct IP.
                        header_up X-Real-IP {remote_host}
                      }
                    '';
                  };
                };
              };
            }
            (mkIf rusticCfg.enable {
              services.rustic.backups = {
                vaultwarden = {
                  environmentFile = config.sops.secrets.rustic_vaultwarden_env.path;
                  timerConfig = {
                    OnCalendar = "*-*-* 03:30:00"; # Run daily at 3:30 a.m.
                    Persistent = true;
                  };
                  settings = {
                    repository = "s3:https://your-s3-endpoint/bucket/vaultwarden";
                    backup = {
                      sources = [
                        vaultCfg.backupDir
                      ];
                    };
                    forget = {
                      keep-daily = 14;
                      keep-weekly = 4;
                      keep-monthly = 12;
                      keep-yearly = 2;
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
                    path = "/var/lib/vaultwarden";
                    user = "vaultwarden";
                    group = "vaultwarden";
                    mode = "0700";
                  }
                  {
                    # The local backup staging area we creates.
                    path = vaultCfg.backupDir;
                    user = "vaultwarden";
                    group = "vaultwarden";
                    mode = "0700";
                  }
                ];
              };
            })
          ];

        # Forcibly replace the upstream backup script with this custom one as it
        # doesn't remove files in the backup even when they are deleted in the
        # original location, which leads to accumulating ghost files.
        # For the full implemention of the upstream script, see:
        # https://github.com/NixOS/nixpkgs/blob/ed142ab1b3a092c4d149245d0c4126a5d7ea00b0/nixos/modules/services/security/vaultwarden/backup.sh
        systemd.services.backup-vaultwarden.serviceConfig.ExecStart = mkForce (
          pkgs.writeShellScript "vaultwarden-rsync-backup" ''
            if [[ -f "$DATA_FOLDER/db.sqlite3" ]]; then
              ${pkgs.sqlite}/bin/sqlite3 "$DATA_FOLDER/db.sqlite3" ".backup '$BACKUP_FOLDER/db.sqlite3'"
            fi

            # Sync all other files and delete missing ones in the destination
            ${pkgs.rsync}/bin/rsync -a --delete --exclude 'db.*' "$DATA_FOLDER/" "$BACKUP_FOLDER/"
          ''
        );

        sops.secrets = {
          "vault/env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "vaultwarden";
          };
          "vault/rustic_env_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "vaultwarden";
          };
        };
      }
    ]
  );
}
