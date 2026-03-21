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
  config = mkIf (anyHasPrefix "scanner" hardwareMods) {
    hardware.sane = {
      enable = true;
      openFirewall = true;
    };
    yakumo.user.extraGroups = [ "scanner" ];
  };
}
