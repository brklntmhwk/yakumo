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
