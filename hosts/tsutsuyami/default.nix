{ inputs, config, lib, ... }:

let inherit (lib) mkDefault;
in {
  imports = [
    ../common

    # hardware configurations are scattered around custom modules and so on.
    # ./hardware-configuration.nix
  ];

  yakumo.system = {
    role = "workstation";
    nix = { enableFlake = true; };
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

  yakumo.hardware = {
    modules = [
      "audio"
      "bluetooth/blueman"
      "cpu/amd"
      "gpu/nvidia"
      "monitor"
      "printer/bambu-lab"
      "scanner/scansnap"
      "ssd"
      # "ups/goldenmate"
    ];
  };

  # Copied from the auto-generated 'hardware-configuration.nix' file.
  # Run `ip link show` or `ip a` to check your interface name(s).
  networking.interfaces.wlp111s0.useDHCP = mkDefault true;

  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-label/TSU_CRYPT";
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/TSU_ROOT";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/TSU_ROOT";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/TSU_ROOT";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/yosuga" = {
    device = "/dev/disk/by-label/TSU_ROOT";
    fsType = "btrfs";
    options = [ "subvol=yosuga" "compress=zstd" "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/TSU_ROOT";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-label/TSU_ROOT";
    fsType = "btrfs";
    options = [ "subvol=swap" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/TSU_BOOT";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [{ device = "/swap/swapfile"; }];

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

  # Don't modify this unless you're sure about the effects.
  system.stateVersion = "25.11";
}
