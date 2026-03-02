# WIP.
# Based on:
# https://github.com/nix-community/nur-combined/blob/1921e651bc87ead82236a61c63a36413b825858b/repos/ataraxiasjel/modules/rustic.nix
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  inherit (utils.systemdUtils.unitOptions) unitOption;
  cfg = config.yakumo.services.rustic;
  tomlFormat = pkgs.formats.toml { };

  backupsSubmodule = _: {
    options = {
      settings = mkOption {
        inherit (tomlFormat) type;
        default = { };
        description = "Rustic profile configuration mapping directly to a TOML file.";
      };
      environmentFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File containing environment variables.";
      };
      timerConfig = mkOption {
        type = types.nullOr (types.attrsOf unitOption);
        default = {
          OnCalendar = "daily";
          Persistent = true;
        };
        description = "Systemd timer configuration for scheduling.";
      };
      user = mkOption {
        type = types.str;
        default = "root";
      };
      initialize = mkOption {
        type = types.bool;
        default = false;
        description = "Create the repository if it doesn't exist.";
      };
      package = mkPackageOption pkgs "rustic" { };
    };
  };
in
{
  options.yakumo.services.rustic = {
    enable = mkEnableOption "rustic";
    backups = mkOption {
      type = types.attrsOf (types.submodule backupsSubmodule);
      default = { };
      description = "Periodic backups to create with Rustic.";
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib)
        filterAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        ;
    in
    {
      systemd.services = mapAttrs' (
        name: backup:
        let
          profile = tomlFormat.generate "${name}.toml" backup.settings;
          rusticCmd = "${backup.package}/bin/rustic -P ${profile}";
        in
        nameValuePair "rustic-backups-${name}" (
          {
            environment.RUSTIC_CACHE_DIR = "/var/cache/rustic-backups-${name}";
            path = [ config.programs.ssh.package ];
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            script = ''
              ${rusticCmd} backup
              ${rusticCmd} forget --prune
            '';
            serviceConfig = {
              Type = "oneshot";
              User = backup.user;
              RuntimeDirectory = "rustic-backups-${name}";
              CacheDirectory = "rustic-backups-${name}";
              CacheDirectoryMode = "0700";
              PrivateTmp = true;
            }
            // optionalAttrs (backup.environmentFile != null) {
              EnvironmentFile = backup.environmentFile;
            };
          }
          // optionalAttrs backup.initialize {
            # Attempt to initialize the repository if requested,
            # failing silently if it already exists.
            preStart = "${rusticCmd} init || true";
          }
        )
      ) cfg.backups;

      systemd.timers = mapAttrs' (
        name: backup:
        nameValuePair "rustic-backups-${name}" {
          inherit (backup) timerConfig;
          wantedBy = [ "timers.target" ];
        }
      ) (filterAttrs (_: backup: backup.timerConfig != null) cfg.backups);
    }
  );
}
