{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    any
    hasPrefix
    mkIf
    ;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (any (mod: hasPrefix "ssd" mod) hardwareMods) {
    boot.initrd.availableKernelModules = [ "nvme" ];
  };
}
