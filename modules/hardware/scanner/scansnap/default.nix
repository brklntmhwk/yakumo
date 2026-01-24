{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    elem
    mkIf
    ;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "scanner/scansnap" hardwareMods) {
    hardware.sane.drivers.scanSnap = {
      enable = true;
    };
  };
}
