{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;
  yosugaCfg = config.yakumo.system.persistence.yosuga;
  isBtrfs = config.fileSystems."/".fsType or "" == "btrfs";
in {
  config = mkIf yosugaCfg.enable {
    # Based on:
    # https://notashelf.dev/posts/impermanence
    boot.initrd.systemd.services.rollback = mkIf isBtrfs {
      description = "Rollback BTRFS root subvolume to a pristine state.";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@crypted.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt

        # Mount the Btrfs top-level (Subvol ID 5).
        mount -o subvolid=5 /dev/mapper/crypted /mnt

        # Ensure the blank snapshot actually exists.
        if [ ! -e /mnt/root-blank ]; then
            echo "CRITICAL ERROR: /mnt/root-blank is missing!"
            echo "Skipping rollback to prevent unbootable system."
            umount /mnt
            exit 1
        fi

        # Move & replace instead of delete & replace.
        # If a 'root' exists, move it aside.
        if [ -e /mnt/root ]; then
            mv /mnt/root /mnt/root-old
        fi

        # Create the new clean root.
        btrfs subvolume snapshot /mnt/root-blank /mnt/root

        # Cleanup the old root (Recursive deletion).
        # Delete 'root-old' now that the new 'root' is safely in place.
        if [ -e /mnt/root-old ]; then
            # Recursively delete subvolumes inside root-old.
            btrfs subvolume list -o /mnt/root-old | cut -f9 -d ' ' |
            while read subvolume; do
                btrfs subvolume delete -c "/mnt/root-old/$subvolume"
            done && btrfs subvolume delete -c /mnt/root-old
        fi

        umount /mnt
      '';
    };
  };
}
