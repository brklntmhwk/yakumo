{ config, lib, pkgs, ... }:

let
  inherit (lib) elem mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in {
  config = mkIf (elem "ups/goldenmate" hardwareMods) {
    power.ups = {
      # https://networkupstools.org/stable-hcl.html
      # GoldenMate UPS 1000VA Pro USB is supported by NUT but the support level is
      # "protocol based on reverse engineering" as of Feb 2026.
      ups.goldenmate = {
        driver = "usbhid-ups";
        port = "auto";
        description = "Golden Mate LiFePO4 UPS.";
        # https://networkupstools.org/docs/man/ups.conf.html
        directives = [
          # https://forum.netgate.com/topic/200045/nut-and-goldenmate-ups/3
          "vendorid = 075d"
          "productid = 0300"
          # WORKAROUND: Golden Mate's "Low Battery" signal can be unreliable.
          # Tell NUT to ignore the hardware flag and calculate it purely based on %.
          "ignorelb" # Ignore Low Battery.
          "override.battery.charge.low = 30"
          "override.battery.charge.warning = 50"
        ];
      };
      # https://networkupstools.org/docs/man/upsmon.conf.html#_configuration_directives
      upsmon.monitor = {
        goldenmate = {
          user = "admin";
          # Make this align with the value of `power.ups.users.admin.upsmon`.
          type = "primary";
          # Form: <upsname>[@<hostname>[:<port>]]
          system = "goldenmate@localhost";
          passwordFile = config.sops.secrets.nut_password_admin.path;
        };
      };
    };
  };
}
