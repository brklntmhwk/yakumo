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
  cfg = config.yakumo.system.networking;
  systemRole = config.yakumo.system.role;
  yosugaCfg = config.yakumo.system.persistence.yosuga;
  isNm = cfg.manager == "networkmanager";
  isNetworkd = cfg.manager == "networkd";
  isWorkstation = systemRole == "workstation";
  isServer = systemRole == "server";
  managers = [
    "networkmanager"
    "networkd"
    "none"
  ];
in
{
  options.yakumo.system.networking = {
    manager = mkOption {
      type = types.enum managers;
      # Networkd is better for servers/routers.
      # https://nixos.wiki/wiki/Systemd-networkd
      default = if isServer then "networkd" else "none";
      description = "Manager of networking.";
    };
  };

  config = mkMerge [
    {
      # Disable global DHCP.
      # Enable it locally if necessary.
      # (e.g., `networking.interfaces.enp112s0.useDHCP = true;`)
      # `systemd.network.wait-online.anyInterface` looks up this value and set it
      # as its default value too.
      networking.useDHCP = mkDefault false;
    }
    (mkIf isNm {
      # https://wiki.nixos.org/wiki/NetworkManager
      networking.networkmanager.enable = true;
      yakumo = {
        user.extraGroups = [ "networkmanager" ];
        system.persistence.yosuga = mkIf yosugaCfg.enable {
          directories = [ "/etc/NetworkManager/system-connections" ];
        };
      };
    })
    (mkIf isNetworkd {
      # Increase the log level.
      # https://nixos.wiki/wiki/Systemd-networkd
      # systemd.services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL =
      #   "debug";

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

      systemd.network = {
        # `systemd-network-wait-online@` service configurations.
        wait-online = {
          # Whether to enable the systemd-networkd-wait-online service.
          enable = mkDefault true; # Default: true
          # Prevent boot hangs caused by networkd waiting for all interfaces to be online.
          # This tells it to proceed as long as at least one is connected.
          anyInterface = mkDefault true; # Default: `config.networking.useDHCP` (true)
          # Specify the timeout limit for the network to appear online (in seconds).
          # Set this to 0 to disable.
          timeout = mkDefault 30; # Default: 120
        };
      };
      boot.initrd.systemd.network = {
        # The initrd (Stage 1) version of the one above.
        wait-online = {
          enable = mkDefault true; # Default: true
          anyInterface = mkDefault true; # Default: `config.networking.useDHCP` (true)
          timeout = mkDefault 15; # Default: 120
        };
      };
    })
    (mkIf (isWorkstation && isNetworkd) {
      systemd.network = {
        # Cover all LAN & WAN interfaces.
        # As for the number prefix, the smaller, the higher the priority is.
        networks = {
          "30-wired" = {
            enable = true;
            linkConfig = {
              # To prevent hangs at boot, explicitly set this to 'no' as it
              # defaults to 'yes' unexpectedly.
              # This tells systemd-networkd, "This port is not always connected and
              # not required to be online".
              RequiredForOnline = "no";
            };
            # This may look more verbose than the one below, but semantically better;
            # you can understand the associations on the face of it.
            matchConfig.Name = "en*"; # e.g., 'enp112s0'
            # This does the exact same thing as above (i.e., Syntactic sugar).
            # https://github.com/NixOS/nixpkgs/commit/f8dbe5f376978947067283c6d03087d7948c50de
            # Is it just me, or wouldn't this sort of abstraction merely cause
            # confusion?
            # name = "en*";
            networkConfig = {
              DHCP = "yes";
            };
          };
          "30-wireless" = {
            enable = true;
            linkConfig = {
              RequiredForOnline = "no"; # Prevent hangs at boot.
            };
            matchConfig.Name = "wl*"; # e.g., 'wlp111s0', 'wlan0'
            networkConfig = {
              DHCP = "yes";
            };
          };
        };
        # Disable the wait-online service for daily drivers.
        wait-online.enable = false;
      };
      # Disable the wait-online service for daily drivers.
      boot.initrd.systemd.network.wait-online.enable = false;
    })
  ];
}
