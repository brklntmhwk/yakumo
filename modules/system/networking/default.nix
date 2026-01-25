{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
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
      networking.useDHCP = mkDefault false;
    }
    (mkIf (cfg.manager == "networkmanager") {
      networking.networkmanager.enable = true;
    })
    # TODO: enough with only this to setup networkd?
    (mkIf (cfg.manager == "networkd") {
      useNetworkd = true;
    })
    # TODO: Any machine specific configs as for networking?
    (mkIf (systemRole == "workstation") {

    })
    (mkIf (systemRole == "server") {

    })
  ];
}
