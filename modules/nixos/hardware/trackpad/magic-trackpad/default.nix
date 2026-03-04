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
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs) bluez usbutils;
    };

    # NOTE: This doesn't work out the cursor-freeze bug.
    # Some users report the exact same bug in Reddit, but no clear solution or workaround
    # seems to be established yet.
    # https://www.reddit.com/r/AsahiLinux/comments/1g2inh6/after_waking_up_from_suspend_apple_magic_trackpad/
    #
    # Simulate unplugging/plugging the USB cable or toggling the power
    # upon waking from sleep to fix the cursor-freeze bug.
    powerManagement.resumeCommands = ''
      # Run in a background subshell so it doesn't block the system wake sequence.
      (
        sleep 2

        # Bluetooth: Restart the Bluetooth stack to force a clean re-pair.
        for mac in $(${pkgs.bluez}/bin/bluetoothctl devices | grep -i "Trackpad" | awk '{print $2}'); do
          ${pkgs.bluez}/bin/bluetoothctl disconnect "$mac" || true
          sleep 1
          ${pkgs.bluez}/bin/bluetoothctl connect "$mac" || true
        done

        # USB: Find the Trackpad and send a hardware-level USB reset signal.
        for dev in $(${pkgs.usbutils}/bin/lsusb | grep -i "Apple" | grep -i "Trackpad" | awk '{print "/dev/bus/usb/"$2"/"$4}' | sed 's/://'); do
          ${pkgs.usbutils}/bin/usbreset "$dev" || true
        done
      ) &
    '';
  };
}
