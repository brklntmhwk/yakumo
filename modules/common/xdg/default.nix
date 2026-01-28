{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.xdg;
  userCfg = config.yakumo.user;
in
{
  options.yakumo.xdg = {
    enable = mkEnableOption "XDG Base Directory";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = userCfg ? name;
          message = "yakumo.xdg requires yakumo.user.name to be set.";
        }
      ];

      environment.sessionVariables = {
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        # Add user binaries to PATH just in case.
        PATH = [
          "$HOME/.local/bin"
        ];
      };

      # This package provides `xdg-user-dirs-update`, which generates
      # '~/.config/user-dirs.dirs'. Some apps consult this file to know where
      # your "Music" or "Downloads" folders actually are.
      environment.systemPackages = [ pkgs.xdg-user-dirs ];
    }
    (mkIf pkgs.stdenv.isLinux (
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
        # 'd': Create directory if it does not exist.
        # Otherwise, it safely fixes permissions/ownership without touching content.
        # Format: Type Path Mode User Group Age Argument
        mkXdgRule = dir: "d /home/${userCfg.name}/${dir} 0755 ${userCfg.name} ${userCfg.group} - -";
      in
      {
        # e.g., `[ "d /home/otogaki/Documents 0755 otogaki yakumo - -" ... ]`
        systemd.tmpfiles.rules = map mkXdgRule xdgDirs;
      }
    ))
  ]);
}
