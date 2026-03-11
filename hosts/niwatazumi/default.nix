# WIP.
{
  config,
  lib,
  ...
}:

{
  imports = [
    ../common

    # hardware configurations are scattered around custom modules and so on.
    # ./hardware-configuration.nix
  ];

  yakumo = {
    system = {
      role = "server";
      nix = {
        enableFlake = true;
      };
      networking = {
        manager = "networkmanager";
        wifi.enable = true;
      };
      # virt = {
      #   microvm.host = {
      #     enable = true;
      #     wanInterface = "enp1s0";
      #   };
      # };
      # persistence.yosuga = {
      #   enable = true;
      #   directories = [
      #     "/etc/nixos"
      #     "/etc/NetworkManager/system-connections"
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
        "cpu/amd"
        "gpu/amd"
        "ssd"
        # "ups/goldenmate"
      ];
    };
  };

  # fileSystems = {

  # };

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
  # system.stateVersion = "25.11";
}
