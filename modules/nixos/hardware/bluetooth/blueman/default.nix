{ config, lib, pkgs, ... }:

let
  inherit (lib) elem mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in {
  config = mkIf (elem "bluetooth/blueman" hardwareMods) {
    # Provides a GUI to pair new devices.
    services.blueman.enable = true;
  };
}
