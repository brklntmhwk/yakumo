{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
    ;
  systemRole = config.yakumo.system.role;
  cfg = config.yakumo.system.networking;
  managers = [
    "networkmanager"
    "networkd"
  ];
in
{
  options.yakumo.system.networking = {
    manager = mkOption {
      type = types.enum managers;
      default = "networkmanager";
      description = "Manager of networking.";
    };
  };

  config = mkMerge [
    {
      # Disable global DHCP.
      # Enable it locally if necessary.
      # (e.g., `networking.interfaces.enp112s0.useDHCP = true;`)
      networking.useDHCP = mkDefault false;
    }
    (mkIf (cfg.manager == "networkmanager") {
      networking.networkmanager.enable = true;
    })
    # TODO: enough with only this to setup networkd?
    (mkIf (cfg.manager == "networkd") {
      # Increase the log level.
      # https://nixos.wiki/wiki/Systemd-networkd
      systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

      # When enabled, this does all the heavy lifting behind the scenes for you:
      # - Set `systemd.network.enable` to true
      # - Add some assertion rules regarding the default gateway and bridges
      # - Add some definitions to `systemd.network.{links|netdevs|networks}`
      # - and more
      # 
      # Disable it if you want to write the network setup on your own.
      # For the detailed instructions, see:
      # https://nixos.wiki/wiki/Systemd-networkd
      networking.useNetworkd = true;
    })
    # TODO: Any machine specific configs as for networking?
    (mkIf (systemRole == "workstation") {
      systemd.network = {
        # Cover all LAN & WAN interfaces.
        # As for the number prefix, the smaller, the higher the priority is.
        networks = {
          "10-cabled" = {
            enable = true;
            name = "en*"; # e.g., 'enp112s0'
            networkConfig.DHCP = "yes";
          };
          "10-wireless" = {
            enable = true;
            name = "wl*"; # e.g., 'wlp111s0'
            networkConfig.DHCP = "yes";
          };
        };
      };
    })
    (mkIf (systemRole == "server") {
      # Networkd is better for servers/routers.
      # https://nixos.wiki/wiki/Systemd-networkd
      yakumo.networking.manager = mkDefault "networkd";
    })
  ];
}
