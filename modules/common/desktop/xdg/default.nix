{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  inherit (murakumo.platforms) isDarwin isLinux;
  cfg = config.yakumo.desktop.xdg;
  userCfg = config.yakumo.user;
in
{
  options.yakumo.desktop.xdg = {
    enable = mkEnableOption "XDG Base Directory";
  };

  config = mkIf cfg.enable (
    let
      xdgDirs = [
        "Desktop"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Public"
        "Templates"
        "Videos"
        ".config"
        ".local/share"
        ".local/state"
        ".cache"
      ];
    in
    mkMerge [
      {
        assertions = [
          {
            assertion = userCfg ? name && userCfg ? home;
            message = "`yakumo.desktop.xdg` requires `yakumo.user.name` and `yakumo.user.home` to be set";
          }
        ];

        environment.sessionVariables = {
          XDG_CACHE_HOME = "${userCfg.home}/.cache";
          XDG_CONFIG_HOME = "${userCfg.home}/.config";
          XDG_DATA_HOME = "${userCfg.home}/.local/share";
          XDG_STATE_HOME = "${userCfg.home}/.local/state";
        };
      }
      (mkIf isDarwin {
        system.activationScripts = {
          xdgDirsSetup.text =
            let
              inherit (lib) concatStringsSep;
              mkDirCmd = dir: ''
                mkdir -p "${userCfg.home}/${dir}"
                chown ${userCfg.name}:staff "${userCfg.home}/${dir}"
              '';
            in
            concatStringsSep "\n" (map mkDirCmd xdgDirs);
        };
      })
      (mkIf isLinux {
        # This package provides `xdg-user-dirs-update`, which generates
        # '~/.config/user-dirs.dirs'. Some apps consult this file to know where
        # your "Music" or "Downloads" folders actually are.
        environment.systemPackages = [ pkgs.xdg-user-dirs ];

        # 'd': Create directory if it doesn't exist.
        # Otherwise, it safely fixes permissions/ownership without touching content.
        # Format: Type Path Mode User Group Age Argument
        # e.g., `[ "d /home/otogaki/Documents 0755 otogaki yakumo - -" ... ]`
        systemd.user.tmpfiles.rules = map (
          dir: "d ${userCfg.home}/${dir} 0755 ${userCfg.name} ${userCfg.group} - -"
        ) xdgDirs;
      })
    ]
  );
}
