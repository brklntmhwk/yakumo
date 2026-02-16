{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf mkMerge;
  cfg = config.yakumo.xdg;
  userCfg = config.yakumo.user;
in
{
  options.yakumo.xdg = {
    enable = mkEnableOption "XDG Base Directory" // {
      default = true;
    };
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
        # '%h' for the home directory.
        # Format: Type Path Mode User Group Age Argument
        mkXdgRule = dir: "d %h/${dir} 0755 - - - -";
      in
      {
        # e.g., `[ "d /home/otogaki/Documents 0755 otogaki yakumo - -" ... ]`
        systemd.user.tmpfiles.rules = map mkXdgRule xdgDirs;
      }
    ))
  ]);
}
