{ config, lib, pkgs, ... }:

let
  inherit (lib) any hasPrefix mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in {
  config = mkIf (any (mod: hasPrefix "ups" mod) hardwareMods) {
    power.ups = {
      enable = true;
      # - "none": doesn't start anything. Use the Integrated Power Management or
      # some external system to start up NUT components.
      # - "standalone": addresses a local only config, with 1 UPS protecting
      # the local system.
      # - "netserver": same as the standalone config, but also needs some more ACLs
      # and possibly a specific LISTEN directive in `upsd.conf`.
      # - "netclient": only requires upsmon.
      mode = "standalone";
      # TODO: revisit this user params and settings.
      users = {
        admin = {
          # https://networkupstools.org/docs/man/upsd.users.html#_fields
          # - "primary": may request FSD (Forced ShutDown), which is equivalent to
          # an 'on battery + low battery' situation for the monitoring purposes.
          # - "secondary": follows critical situations to shut down when needed.
          upsmon = "primary";
          actions = [ "set" "fsd" ];
          instcmds = [ "all" ];
          passwordFile = config.sops.secrets.nut_password_admin.path;
        };
        upsmon = {
          upsmon = "secondary";
          passwordFile = config.sops.secrets.nut_password_upsmon.path;
        };
      };
      upsmon = {
        # https://networkupstools.org/docs/man/upsmon.conf.html#_configuration_directives
        # settings = [];
      };
    };

    yakumo.user = {
      name = "upsmon"; # Make this align with `power.ups.users.<name>`.
      isSystemUser = true;
      group = "nut";
    };
  };
}
