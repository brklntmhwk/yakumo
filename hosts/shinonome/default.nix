{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkForce;
in
{
  imports = [
    ../common

    # hardware configurations are scattered around custom modules and so on.
    # ./hardware-configuration.nix
  ];

  hardware.asahi = {
    enable = true;
    extractPeripheralFirmware = true;
    peripheralFirmwareDirectory = ./firmware;
    setupAsahiSound = true;
  };

  yakumo = {
    system = {
      role = "workstation";
      nix = {
        enableFlake = true;
      };
      networking = {
        manager = "networkmanager";
        wifi.enable = true;
      };
      # persistence.yosuga = {
      #   enable = true;
      #   directories = [
      #     "/etc/nixos"
      #     "/etc/NetworkManager/system-connections"
      #     "/var/lib/bluetooth"
      #   ];
      #   files = [
      #     "/etc/machine-id"
      #     "/etc/ssh/ssh_host_ed25519_key"
      #     "/etc/ssh/ssh_host_ed25519_key.pub"
      #     "/etc/ssh/ssh_host_rsa_key"
      #     "/etc/ssh/ssh_host_rsa_key.pub"
      #   ];
      # };
    };
    hardware = {
      modules = [
        "audio"
        "bluetooth/blueman"
        "gpu/asahi"
        "monitor"
        "ssd"
        "token/yubikey/fido-u2f"
        "token/yubikey/piv"
        "trackpad/magic-trackpad"
      ];
    };
  };

  # Run `ip link show` or `ip a` to check your interface name(s).
  # networking.interfaces.wlan0.useDHCP = mkDefault true;

  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-label/SHI_CRYPT";
    allowDiscards = true;
    # Instruct systemd-cryptsetup to wait for and use your FIDO2 token.
    crypttabExtraOpts = [ "fido2-device=auto" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/SHI_ROOT";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "compress=zstd"
        "noatime"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-label/SHI_ROOT";
      fsType = "btrfs";
      options = [
        "subvol=home"
        "compress=zstd"
        "noatime"
      ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/SHI_ROOT";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "compress=zstd"
        "noatime"
      ];
    };
    "/yosuga" = {
      device = "/dev/disk/by-label/SHI_ROOT";
      fsType = "btrfs";
      options = [
        "subvol=yosuga"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/var/log" = {
      device = "/dev/disk/by-label/SHI_ROOT";
      fsType = "btrfs";
      options = [
        "subvol=log"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/swap" = {
      device = "/dev/disk/by-label/SHI_ROOT";
      fsType = "btrfs";
      options = [
        "subvol=swap"
        "noatime"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2DBD-07F0";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  swapDevices = [ { device = "/swap/swapfile"; } ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      # Run `locale` to see available options.
    };
    extraLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      asahi-btsync # Bluetooth pairing keys sync with macOS on ARM Macs.
      asahi-wifisync # Wifi passwords sync with macOS on ARM Macs.
      asahi-bless # Tool to select active boot partition on ARM Macs.
      asahi-nvram # Tool to read and write nvram variables on ARM Macs.
      ;
  };

  # Don't modify this unless you're sure about the effects.
  system.stateVersion = "25.11";
}
