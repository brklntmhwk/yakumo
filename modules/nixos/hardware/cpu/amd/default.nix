{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    elem
    mkDefault
    mkIf
    ;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "cpu/amd" hardwareMods) {
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    boot.kernelModules = [ "kvm-amd" ];
  };
}
