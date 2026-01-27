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
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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

  yakumo.secrets = {
    sops = {
      enable = true;
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

  yakumo.services = {
    openssh = {
      enable = true;
    };
  };

  # Copied from the auto-generated 'hardware-configuration.nix' file.
  # Run `ip link show` or `ip a` to check your interface name(s).
  networking.interfaces.wlp111s0.useDHCP = mkDefault true;

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
