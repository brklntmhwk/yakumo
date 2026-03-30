# Based on:
# https://github.com/nix-community/impermanence/blob/7b1d382faf603b6d264f58627330f9faa5cba149/nixos.nix
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
    types
    ;
  cfg = config.yakumo.system.persistence.yosuga;

  # Standardize module options for files and directories.
  mkPersistentOption = type: {
    path = mkOption {
      type = types.str;
      example = if type == "directory" then "/var/lib/nixos" else "/etc/machine-id";
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
  };
in
{
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
      type = types.listOf (
        types.coercedTo types.str (path: { inherit path; }) (
          types.submodule { options = mkPersistentOption "directory"; }
        )
      );
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
      type = types.listOf (
        types.coercedTo types.str (path: { inherit path; }) (
          types.submodule { options = mkPersistentOption "file"; }
        )
      );
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

  config = mkIf cfg.enable (
    let
      inherit (lib) any concatStringsSep optional;

      mountOptions = [
        "bind"
        "x-gvfs-hide" # Hide bind mounts from file managers.
        "X-fstrim.notrim" # Don't discard unused blocks on a mounted filesystem.
      ]
      ++ (optional cfg.allowTrash "x-gvfs-trash");
      baseBindMountConfig = {
        type = "none";
        unitConfig.DefaultDependencies = false;
        options = concatStringsSep "," mountOptions;
      };
    in
    {
      assertions =
        let
          inherit (lib) catAttrs length unique;

          duplicationMsg = target: "Duplicate ${target} found in persistence configuration";
          hasUniquePaths =
            list:
            let
              paths = catAttrs "path" list;
            in
            length (unique paths) == length paths;
        in
        [
          {
            assertion = cfg.persistentStoragePath != "/";
            message = "The persistent storage path cannot be root";
          }
          {
            assertion = hasUniquePaths cfg.directories;
            message = duplicationMsg "directories";
          }
          {
            assertion = hasUniquePaths cfg.files;
            message = duplicationMsg "files";
          }
        ];

      boot.initrd.systemd = {
        # https://github.com/nix-community/impermanence/commit/1b02741e3d154a4bc59af55989ea66528e84b371
        suppressedUnits = mkIf (any (f: f.path == "/etc/machine-id") cfg.files) [
          "systemd-machine-id-commit.service"
        ];
        # Bind-mount only the persistent directories required at Stage 1 (initrd).
        mounts =
          let
            inherit (lib) elem filter;
            inherit (utils) pathsNeededForBoot;
            initrdDirs = filter (d: elem d.path pathsNeededForBoot) cfg.directories;

            mkInitrdBindMount =
              d:
              {
                description = "Bind mount for persistent stage 1 directory ${d.path}.";
                before = [ "initrd-nixos-activation.service" ];
                wantedBy = [ "initrd.target" ];
                what = "/sysroot${cfg.persistentStoragePath}${d.path}";
                where = "/sysroot${d.path}";
              }
              // baseBindMountConfig;
          in
          map mkInitrdBindMount initrdDirs;
      };

      systemd = {
        # https://github.com/nix-community/impermanence/commit/1b02741e3d154a4bc59af55989ea66528e84b371
        services.systemd-machine-id-commit.unitConfig.ConditionFirstBoot = mkIf (any (
          f: f.path == "/etc/machine-id"
        ) cfg.files) true;
        # Do some pre-flight checks to ensure the target/source directories and files exist.
        tmpfiles.rules =
          let
            inherit (builtins) concatMap;

            # Format: Type Path Mode User Group Age Argument
            # 'd': Create the directory if it doesn't exist.
            mkDirRules = d: [
              "d ${cfg.persistentStoragePath}${d.path} ${d.mode} ${d.user} ${d.group} -"
              "d ${d.path} ${d.mode} ${d.user} ${d.group} -"
            ];
            # 'f': Create the file if it doesn't exist.
            mkFileRules = f: [
              "f ${cfg.persistentStoragePath}${f.path} ${f.mode} ${f.user} ${f.group} -"
              "f ${f.path} ${f.mode} ${f.user} ${f.group} -"
            ];
          in
          (concatMap mkDirRules cfg.directories) ++ (concatMap mkFileRules cfg.files);
        # Bind-mount the persistent directories and files using systemd mount.
        mounts =
          let
            mkBindMount =
              type: item:
              {
                description = "Bind mount for persistent ${type} ${item.path}.";
                before = [ "local-fs.target" ];
                wantedBy = [ "local-fs.target" ];
                what = "${cfg.persistentStoragePath}${item.path}";
                where = item.path;
              }
              // baseBindMountConfig;
          in
          map (mkBindMount "directory") cfg.directories ++ map (mkBindMount "file") cfg.files;
      };
    }
  );
}
