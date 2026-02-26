{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkMerge;
  yosugaCfg = config.yakumo.system.persistence.yosuga;
  isBtrfs = config.fileSystems."/".fsType or "" == "btrfs";
  # Based on:
  # https://mt-caret.github.io/blog/posts/2020-06-29-optin-state.html
  btrfs-diff = pkgs.writeShellApplication {
    name = "btrfs-diff";

    # Inject the required tools into the script's PATH
    runtimeInputs = with pkgs; [
      btrfs-progs
      coreutils
      gnused
    ];

    text = ''
      # Fallback assuming manual mounting at /mnt
      ROOT_BLANK="/mnt/root-blank"
      ROOT_SUBVOL="/mnt/root"

      if [ ! -d "$ROOT_BLANK" ]; then
        echo "Error: $ROOT_BLANK not found."
        echo "Please mount your Btrfs top-level subvolume."
        exit 1
      fi

      OLD_TRANSID=$(sudo btrfs subvolume find-new "$ROOT_BLANK" 9999999)

      # Use ''${...} to escape Nix string interpolation.
      OLD_TRANSID=''${OLD_TRANSID#transid marker was }

      echo "Scanning for new files since transaction ID: $OLD_TRANSID..."

      btrfs subvolume find-new "$ROOT_SUBVOL" "$OLD_TRANSID" | \
        sed '$d' | \
        cut -f17- -d' ' | \
        sort | \
        uniq | \
        while read -r path; do
          path="/$path"
          if [ -L "$path" ]; then
            : # Ignore symlinks (usually NixOS store links).
          elif [ -d "$path" ]; then
            : # Ignore directories.
          else
            echo "$path"
          fi
        done
    '';
  };
in
{
  config = mkIf yosugaCfg.enable (mkMerge [
    (mkIf isBtrfs {
      # Based on:
      # https://notashelf.dev/posts/impermanence
      boot.initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state.";
        wantedBy = [ "initrd.target" ];
        # NOTE: Change '@<your_device_mapper_name>' according to your naming.
        # Format: 'systemd-cryptsetup@<your_device_mapper_name>.service'
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
                  btrfs subvolume delete -c "/mnt/$subvolume"
              done && btrfs subvolume delete -c /mnt/root-old
          fi

          umount /mnt
        '';
      };

      environment.systemPackages = [ btrfs-diff ];
    })
  ]);
}
