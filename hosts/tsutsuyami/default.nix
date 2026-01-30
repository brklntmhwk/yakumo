{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault;
in
{
  imports = [
    ../common

    # hardware configurations are now scattered around custom modules and so on.
    # ./hardware-configuration.nix
  ];

  yakumo.system = {
    role = "workstation";
    nix = {
      enableFlake = true;
    };
    networking = {
      manager = "networkd";
      wifi.enable = true;
    };
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
    ];
  };

  # Copied from the auto-generated 'hardware-configuration.nix' file.
  # Run `ip link show` or `ip a` to check your interface name(s).
  networking.interfaces.wlp111s0.useDHCP = mkDefault true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d3bc9213-ebee-4ae4-befa-0340c1b07555";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8018-1454";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/c668f084-2996-4f68-bbd2-97a639656feb"; }
  ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      # Run `locale` to see available options
    };
    extraLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
  };

  # Don't modify this unless you're sure about the effects.
  system.stateVersion = "24.11";
}
