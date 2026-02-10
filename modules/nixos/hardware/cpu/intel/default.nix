{ config, lib, pkgs, ... }:

let
  inherit (lib) elem mkDefault mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in {
  config = mkIf (elem "cpu/intel" hardwareMods) {
    hardware.cpu.intel.updateMicrocode =
      lib.mkDefault config.hardware.enableRedistributableFirmware;
    boot.kernelModules = [ "kvm-intel" ];
  };
}
