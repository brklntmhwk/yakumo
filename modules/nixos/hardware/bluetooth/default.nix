{ config, lib, pkgs, ... }:

let
  inherit (lib) any hasPrefix mkIf mkOption;
  hardwareMods = config.yakumo.hardware.modules;
in {
  config = mkIf (any (mod: hasPrefix "bluetooth" mod) hardwareMods) {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      # For the full configuration options, see:
      # https://github.com/bluez/bluez/blob/master/src/main.conf
      settings = {
        General = {
          # Restricts all controllers to the BR/EDR specification.
          # Possible values: 'dual' 'le' 'bredr'
          ControllerMode = "bredr";
          # Enables D-Bus experimental interfaces.
          Experimental = true;
          # Consumes slightly more power but makes connecting devices feel snappier.
          FastConnectable = true;
          # Allows peripheral devices (e.g., mice, keyboards, etc.) to re-pair without
          # having to manually remove and add the device.
          JustWorksRepairing = "always";
        };
        Policy = {
          # Ensures the Bluetooth controller is fully up and ready to pair or accept
          # connections immediately after boot, without needing a manual "power on"
          # software toggle.
          AutoEnable = true; # 'true' by default though
          # Disable reconnections.
          ReconnectAttempts = 0;
        };
      };
    };
  };
}
