{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.yakumo.services.printing;
in
{
  options.yakumo.services.printing = {
    enable = mkEnableOption "printing service";
  };

  config = mkIf cfg.enable {
    services.printing = {
      # Allow the machine for sharing local printers by default.
      defaultShared = true;
      # Allow unconditional access from all interfaces.
      allowFrom = [
        "all" # Default: "localhost"
      ];
      # Force the machine to listen on all interfaces and act as a print server
      # for other computers on the network.
      listenAddresses = [
        "*:631" # Default: "localhost:631"
      ];
    };
    # Need to manually open port 631 in the firewall so traffic from outside
    # can reach it.
    networking.firewall = {
      allowedUDPPorts = [ 631 ];
      allowedTCPPorts = [ 631 ];
    };
  };
}
