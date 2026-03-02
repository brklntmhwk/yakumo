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
  config = mkIf (elem "gpu/asahi" hardwareMods) {
    hardware = {
      graphics.enable32Bit = mkForce false;
    };
  };
}
