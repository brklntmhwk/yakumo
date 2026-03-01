{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) elem mkIf;
  hardwareMods = config.yakumo.hardware.modules;
  cfg = config.yakumo.hardware.trackpad.magic-trackpad;
in
{
  config = mkIf (elem "trackpad/magic-trackpad" hardwareMods) {
    # Reload the Apple Magic Trackpad driver upon waking from sleep
    # to fix the cursor-freeze bug.
    powerManagement.resumeCommands = ''
      # Run in a background subshell so it doesn't block the system wake sequence.
      (
        # Wait a while for the USB/Bluetooth bus to power back up.
        sleep 2

        # Unload and reload the Apple trackpad driver.
        ${pkgs.kmod}/bin/modprobe -r hid_magicmouse || true
        ${pkgs.kmod}/bin/modprobe hid_magicmouse
      ) &
    '';
  };
}
