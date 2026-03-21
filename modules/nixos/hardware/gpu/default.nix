{
  config,
  lib,
  murakumo,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "gpu" hardwareMods) {
    hardware.graphics = {
      enable = true;
    };
  };
}
