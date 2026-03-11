{
  config,
  lib,
  pkgs,
  murakumo,
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
  cfg = config.yakumo.desktop.daemons.mako;
  iniFormat = pkgs.formats.ini { };
  iniAtomType = iniFormat.lib.types.atom;
in
{
  options.yakumo.desktop.daemons.mako = {
    enable = mkEnableOption "mako";
    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          iniAtomType
          (types.attrsOf iniAtomType)
        ]
      );
      default = { };
      description = ''
        Mako configuration in Nix-representable format.
        For the valid setting options, see:
        https://github.com/emersion/mako/blob/master/doc/mako.5.scd
      '';
      example = {
        actions = true;
        history = 1; # Conventional flag is also acceptable (1: true, 0: false)
        anchor = "top-right";
        default-timeout = 0;
        "mode=do-not-disturb" = {
          invisible = true;
        };
      };
    };
    package = mkPackageOption pkgs "mako" { };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getExe;
      inherit (pkgs) writeText;
      inherit (murakumo.generators) toMakoConf;

      makoConf = writeText "config" (toMakoConf {
        attrs = cfg.settings;
      });
    in
    {
      yakumo.user.packages = [ cfg.package ];

      systemd.user.services.mako = {
        unitConfig = {
          After = [ "graphical-session.target" ];
          Description = "Mako: Notification daemon.";
          Documentation = "man:mako(1)";
          PartOf = [ "graphical-session.target" ];
        };
        serviceConfig = {
          BusName = "org.freedesktop.Notifications";
          ExecReload = "${cfg.package}/bin/makoctl reload";
          ExecStart = "${getExe cfg.package} --config ${makoConf}";
          Restart = "on-failure";
          RestartSec = 1;
          Type = "dbus";
        };
        wantedBy = [ "graphical-session.target" ];
      };
    }
  );
}
