# Based on:
# https://github.com/nix-community/impermanence/blob/7b1d382faf603b6d264f58627330f9faa5cba149/nixos.nix
{ config, lib, pkgs, utils, ... }:

let
  inherit (lib)
    any concatMapStringsSep concatStringsSep length listToAttrs mkEnableOption
    mkIf mkOption optional optionalString types unique;
  inherit (utils) escapeSystemdPath;
  cfg = config.yakumo.system.persistence.yosuga;

  # Standardize module options for files and directories.
  mkPersistentOption = type: {
    path = mkOption {
      type = types.str;
      example =
        if type == "directory" then "/var/lib/nixos" else "/etc/machine-id";
      description = "The absolute path to the ${type} to persist.";
    };
    user = mkOption {
      type = types.str;
      default = "root";
      example = "yakumo";
      description = "Owner of the source ${type}.";
    };
    group = mkOption {
      type = types.str;
      default = "root";
      example = "users";
      description = "Group of the source ${type}.";
    };
    mode = mkOption {
      type = types.str;
      default = if type == "directory" then "0755" else "0644";
      example = "0700";
      description = "Permissions mode for the source ${type}.";
    };
    neededForBoot = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description =
        "Whether this ${type} is needed for boot (i.e., Mounts in initrd/early boot).";
    };
  };
in {
  options.yakumo.system.persistence.yosuga = {
    enable = mkEnableOption ''
      yosuga (the "Erase Your Darlings" philosophy)
    '';
    persistentStoragePath = mkOption {
      type = types.path;
      default = "/yosuga";
      example = "/persist";
      description = "The path where persistent data are stored.";
    };
    directories = mkOption {
      type = types.listOf (types.coercedTo types.str (path: { inherit path; })
        (types.submodule { options = mkPersistentOption "file"; }));
      default = [ ];
      example = [
        "/var/log"
        {
          path = "/var/lib/bluetooth";
          mode = "0700";
        }
      ];
      description = "List of directories to bind mount.";
    };
    files = mkOption {
      type = types.listOf (types.coercedTo types.str (path: { inherit path; })
        (types.submodule { options = mkPersistentOption "directory"; }));
      default = [ ];
      example = [
        "/etc/machine-id"
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          user = "root";
        }
      ];
      description = "List of files to bind mount.";
    };
    hideMounts = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to hide bind mounts from file managers.
        Uses x-gvfs-hide internally.
      '';
    };
    allowTrash = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to allow trashing files on these mounts.
        Uses x-gvfs-trash internally.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = let
      duplicationMsg = target:
        "Duplicate ${target} found in persistence configuration";
    in [
      {
        assertion = cfg.persistentStoragePath != "/";
        message = "The persistent storage path cannot be root";
      }
      {
        assertion = (length (unique (map (x: x.path) cfg.directories)))
          == (length cfg.directories);
        message = duplicationMsg "directories";
      }
      {
        assertion = (length (unique (map (x: x.path) cfg.files)))
          == (length cfg.files);
        message = duplicationMsg "files";
      }
    ];

    # https://github.com/nix-community/impermanence/commit/1b02741e3d154a4bc59af55989ea66528e84b371
    boot.initrd.systemd.suppressedUnits =
      mkIf (any (f: f.path == "/etc/machine-id") cfg.files)
      [ "systemd-machine-id-commit.service" ];
    systemd.services.systemd-machine-id-commit.unitConfig.ConditionFirstBoot =
      mkIf (any (f: f.path == "/etc/machine-id") cfg.files) true;

    fileSystems = listToAttrs (map (dir: {
      name = dir.path;
      value = {
        device = "${cfg.persistentStoragePath}${dir.path}";
        fsType = "none";
        options = [
          "bind"
          "noatime" # No Access Time. Disable atime updates.
          "X-mount.mkdir" # Allow to execute mkdir if the target does not exist yet.
          "X-fstrim.notrim" # Disable trimming.
        ] ++ (optional cfg.hideMounts "x-gvfs-hide")
          ++ (optional cfg.allowTrash "x-gvfs-trash");
        neededForBoot = dir.neededForBoot;
        noCheck = true; # Skip fsck on this.
      };
    }) cfg.directories);

    systemd.mounts = map (file:
      let
        safePath = escapeSystemdPath file.path;
        mountOptions = [ "bind" ] ++ (optional cfg.hideMounts "x-gvfs-hide")
          ++ (optional cfg.allowTrash "x-gvfs-trash");
      in {
        type = "none";
        description = "Bind mount for persistent file ${file.path}";
        before = [ "local-fs.target" ];
        requiredBy = optional file.neededForBoot "sysinit.target";
        wantedBy = [ "local-fs.target" ];
        what = "${cfg.persistentStoragePath}${file.path}";
        where = file.path;
        options = concatStringsSep "," mountOptions;
        # Prepare the target and source before mounting.
        mountConfig = {
          ExecStartPre = pkgs.writeShellScript "ensure-target-${safePath}" ''
            set -eu
            mkdir -p "$(dirname ${file.path})"

            # Ensure source exists in the persistent storage path.
            # (This avoids the bind mount failing if the source is missing)
            if [ ! -e "${cfg.persistentStoragePath}${file.path}" ]; then
              mkdir -p "$(dirname "${cfg.persistentStoragePath}${file.path}")"

              # Treat machine-id specially.
              if [ "${file.path}" = "/etc/machine-id" ]; then
                 echo "uninitialized" > "${cfg.persistentStoragePath}${file.path}"
              else
                 touch "${cfg.persistentStoragePath}${file.path}"
              fi
            fi

            # Ensure target exists (mount point).
            if [ ! -e "${file.path}" ]; then
              touch "${file.path}"
            fi
          '';
        };
      }) cfg.files;

    system.activationScripts.persistent-storage = {
      text = let
        mkScript = type: item: ''
          # Create source paths.
          targetPath="${cfg.persistentStoragePath}${item.path}"
          dirPath=$(dirname "$targetPath")

          # Ensure directories and files exist.
          mkdir -p "$dirPath"
          ${optionalString (type == "directory") ''mkdir -p "$targetPath"''}
          ${optionalString (type == "file") ''
            if [ ! -e "$targetPath" ]; then
              touch "$targetPath"
            fi
          ''}

          # Apply declared permissions.
          if [ -e "$targetPath" ]; then
            chown ${item.user}:${item.group} "$targetPath"
            chmod ${item.mode} "$targetPath"
          fi
        '';
      in ''
        echo "Setting up persistent storage permissions..."
        ${concatMapStringsSep "\n" (mkScript "directory") cfg.directories}
        ${concatMapStringsSep "\n" (mkScript "file") cfg.files}
      '';
      deps = [ "users" "groups" ];
    };
  };
}
