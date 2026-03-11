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
  cfg = config.yakumo.desktop.daemons.cliphist;
in
{
  options.yakumo.desktop.daemons.cliphist = {
    enable = mkEnableOption "cliphist";
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [
        "-max-dedupe-search"
        "10"
        "-max-items"
        "500"
      ];
      description = "Arguments to append to the cliphist command.";
      example = [
        "-max-items"
        "100"
      ];
    };
    clipboardPackage = mkPackageOption pkgs "wl-clipboard" { };
    package = mkPackageOption pkgs "cliphist" { };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) escapeShellArgs getExe getExe';
      extraArgsStr = escapeShellArgs cfg.extraArgs;
    in
    {
      yakumo.user.packages = [ cfg.package ];

      systemd.user.services.cliphist = {
        unitConfig = {
          After = [ "graphical-session.target" ];
          Description = "Cliphist: Clipboard management daemon.";
          PartOf = [ "graphical-session.target" ];
        };
        serviceConfig = {
          ExecStart = "${getExe' cfg.clipboardPackage "wl-paste"} --watch ${getExe cfg.package} ${extraArgsStr} store";
          Restart = "on-failure";
          Type = "simple";
        };
        wantedBy = [ "graphical-session.target" ];
      };
    }
  );
}
