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
        flake.enable = true;
      };
      networking = {
        manager = "networkmanager";
        wifi.enable = true;
      };
    };
    hardware = {
      modules = [
        "cpu/intel"
        "ssd"
        # "ups/goldenmate"
      ];
    };
    services = {
      adguardhome = {
        enable = true;
      };
      caddy = {
        enable = true;
      };
      home-assistant = {
        enable = true;
      };
      kanidm = {
        enable = true;
      };
      mosquitto = {
        enable = true;
      };
      owntracks = {
        enable = true;
        mqttIntegration = {
          enable = true;
        };
        frontend = {
          enable = true;
        };
      };
      vaultwarden = {
        enable = true;
      };
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
