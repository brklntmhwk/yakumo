# WIP.
{
  inputs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.yakumo.system.virt.microvm.host;
in
{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  options.yakumo.system.virt.microvm.host = {
    enable = mkEnableOption "MicroVM host infrastructure";
    wanInterface = mkOption {
      type = types.str;
      description = "The physical network interface connected to your router/switch (e.g., enp3s0).";
    };
  };

  config = mkIf cfg.enable {
    # Enable the MicroVM host daemon.
    # This provides the CLI tools and Systemd management for the hypervisors.
    microvm = {
      # We don't have to do this, but enable it explicitly.
      host.enable = true; # Default: true
    };

    networking = {
      # Establish the Network Bridge.
      # This creates 'br0'. The standalone VMs will plug their 'tap' interfaces into this.
      bridges = {
        "br0" = {
          interfaces = [ cfg.wanInterface ];
        };
      };
      interfaces = {
        # Allow the host to get an IP address on the bridge so it remains accessible.
        "br0" = {
          useDHCP = true;
        };
        # Ensure DHCP isn't trying to grab IPs on the raw physical interface anymore.
        "${cfg.wanInterface}" = {
          useDHCP = false;
        };
      };
      firewall.trustedInterfaces = [ "br0" ];
    };

    # Kernel IP Forwarding
    # Essential for VMs to route traffic out to the internet.
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
  };
}
