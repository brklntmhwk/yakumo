{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
  cfg = config.yakumo.desktop.daemons.mako;
  iniFormat = pkgs.formats.ini { };
  iniAtomType = iniFormat.lib.types.atom;
in {
  options.yakumo.desktop.daemons.mako = {
    enable = mkEnableOption "mako";
    settings = mkOption {
      type =
        types.attrsOf (types.oneOf [ iniAtomType (types.attrsOf iniAtomType) ]);
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
        "mode=do-not-disturb" = { invisible = true; };
      };
    };
    package = mkPackageOption pkgs "mako" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Mako package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (let
    inherit (lib) getExe getName;
    inherit (pkgs) writeText;
    inherit (murakumo.wrappers) mkAppWrapper;
    inherit (murakumo.generators) toMakoConf;

    makoConf = writeText "config" (toMakoConf { attrs = cfg.settings; });
    makoWrapped = mkAppWrapper {
      pkg = cfg.package;
      name = "${getName cfg.package}-${config.yakumo.user.name}";
      flags = [ "--config" makoConf ];
    };
  in {
    yakumo.desktop.daemons.mako.packageWrapped = makoWrapped;
    yakumo.user.packages = [ makoWrapped ];

    systemd.user.services.mako = {
      unitConfig = {
        After = [ "graphical-session.target" ];
        Description = "Mako: Notification daemon";
        Documentation = "man:mako(1)";
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        BusName = "org.freedesktop.Notifications";
        ExecReload = "${makoWrapped}/bin/makoctl reload";
        ExecStart = "${getExe makoWrapped}";
        Restart = "on-failure";
        RestartSec = 1;
        Type = "dbus";
      };
      wantedBy = [ "graphical-session.target" ];
    };
  });
}
