{
  config,
  lib,
  pkgs,
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
      # https://wiki.nixos.org/wiki/NetworkManager
      networking.networkmanager.enable = true;
      yakumo.user.extraGroups = [ "networkmanager" ];
    })
    (mkIf (cfg.manager == "networkd") {
      # Increase the log level.
      # https://nixos.wiki/wiki/Systemd-networkd
      systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

      # When enabled, this does all the heavy lifting behind the scenes for you:
      # - Set `systemd.network.enable` to true
      # - Add some assertion rules regarding the default gateway and bridges
      # - Set `networking.dhcpcd.enable` to false
      # - Add some definitions to `systemd.network.{links|netdevs|networks}`
      # referring to those `networking.*` options (e.g., `bonds`, `fooOverUDP`,
      # `greTunnels`, `ipips`, `macvlans`, etc.)
      #
      # Disable it if you want to write the network setup on your own.
      # For the detailed instructions, see:
      # https://nixos.wiki/wiki/Systemd-networkd
      networking.useNetworkd = true;
    })
    (mkIf (systemRole == "workstation") {
      systemd.network = {
        # Cover all LAN & WAN interfaces.
        # As for the number prefix, the smaller, the higher the priority is.
        networks = {
          "30-wired" = {
            enable = true;
            # This may look more verbose than the one below, but semantically better;
            # you can understand the associations on the face of it.
            matchConfig.Name = "en*"; # e.g., 'enp112s0'
            # This does the exact same thing as above. (i.e., Syntactic sugar)
            # https://github.com/NixOS/nixpkgs/commit/f8dbe5f376978947067283c6d03087d7948c50de
            # Is it just me, or wouldn't this sort of abstraction merely cause
            # confusion?
            # name = "en*";
            networkConfig.DHCP = "yes";
          };
          "30-wireless" = {
            enable = true;
            matchConfig.Name = "wl*"; # e.g., 'wlp111s0'
            networkConfig.DHCP = "yes";
          };
        };
      };
    })
    (mkIf (systemRole == "server") {
      # Networkd is better for servers/routers.
      # https://nixos.wiki/wiki/Systemd-networkd
      yakumo.system.networking.manager = mkDefault "networkd";
    })
  ];
}
