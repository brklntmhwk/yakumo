{ config, lib, pkgs, ... }:

let
  inherit (lib) any hasPrefix mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in {
  config = mkIf (any (mod: hasPrefix "scanner" mod) hardwareMods) {
    hardware.sane = {
      enable = true;
      openFirewall = true;
    };
    yakumo.user.extraGroups = [ "scanner" ];
  };
}
