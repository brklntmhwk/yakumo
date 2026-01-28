{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    any
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  inherit (murakumo.utils) anyEnabled getDirNames;
  cfg = config.yakumo.desktop.compositors;
in
{
  config = mkIf (anyEnabled cfg) {
    services.dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };
  };
}
