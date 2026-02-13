{ inputs, config, lib, ... }:

let inherit (lib) mkDefault mkForce;
in {
  imports = [
    ../common

    # hardware configurations are scattered around custom modules and so on.
    # ./hardware-configuration.nix
  ];

  # hardware.asahi = { };

  boot = { loader.efi.canTouchEfiVariables = mkForce false; };

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
    modules = [ "audio" "bluetooth/blueman" "monitor" "ssd" ];
  };

  # Copied from the auto-generated 'hardware-configuration.nix' file.
  # Run `ip link show` or `ip a` to check your interface name(s).
  # networking.interfaces.wlp111s0.useDHCP = mkDefault true;

  # fileSystems."/" = { };

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
  # system.stateVersion = "xx.yy";
}
