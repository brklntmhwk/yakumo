{
  config,
  lib,
  ...
}:

let
  inherit (lib) elem mkForce mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "gpu/amd" hardwareMods) {
    hardware = {
      graphics.enable32Bit = true;
      # This sets `boot.initrd.kernelModules = [ "amdgpu" ];`.
      amdgpu.initrd.enable = true;
    };
  };
}
