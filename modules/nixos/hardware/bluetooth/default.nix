{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    ;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
  yosugaCfg = config.yakumo.system.persistence.yosuga;
in
{
  config = mkIf (anyHasPrefix "bluetooth" hardwareMods) {
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

    yakumo.system.persistence.yosuga = mkIf yosugaCfg.enable {
      directories = [ "/var/lib/bluetooth" ];
    };
  };
}
