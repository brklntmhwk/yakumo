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
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.desktop.daemons.awww;
in
{
  options.yakumo.desktop.daemons.awww = {
    enable = mkEnableOption "awww-daemon";
    package = mkPackageOption pkgs "awww" { };
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Options passed to awww-daemon.
        See `awww-daemon --help` for more information.
      '';
      example = [
        "--no-cache"
        "--layer"
        "bottom"
      ];
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) escapeShellArgs getExe' makeBinPath;
    in
    {
      yakumo.user.package = [ cfg.package ];

      # https://github.com/nix-community/home-manager/blob/b3ccd4bb262f4e6d3248b46cede92b90c4a42094/modules/services/swww.nix
      systemd.user.services.awww-daemon = {
        unitConfig = {
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Description = "Awww-Daemon: An Answer to your Wayland Wallpaper Woes.";
          Documentation = "https://codeberg.org/LGFae/awww/src/branch/main/README.md";
          PartOf = [ "graphical-session.target" ];
        };
        serviceConfig = {
          Environment = [
            "PATH=$PATH:${makeBinPath [ cfg.package ]}"
          ];
          ExecStart = "${getExe' cfg.package "swww-daemon"} ${escapeShellArgs cfg.extraArgs}";
          Restart = "always";
          RestartSec = 10;
        };
      };
    }
  );
}
