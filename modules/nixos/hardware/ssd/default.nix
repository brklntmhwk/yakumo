{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "ssd" hardwareMods) {
    boot.initrd.availableKernelModules = [ "nvme" ];
  };
}
