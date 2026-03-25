{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "printer" hardwareMods) {
    services = {
      avahi = {
        enable = true;
        domainName = "local"; # Default: 'local'
        # Open the firewall for UDP port 5353.
        openFirewall = true; # Default: true
        ipv4 = true; # Default: true
        ipv6 = true; # Default: true (config.networking.enableIPv6)
        # Whether to enable the mDNS NSS (Name Service Switch) plug-in for IPv4.
        # Enabling it allows applications to resolve names in the .local domain
        # by transparently querying the avahi-daemon.
        nssmdns4 = true; # Default: false
        # The IPv6 version of `nssmdns4`.
        # Given the fact that most mDNS responders only register local IPv4 addresses,
        # most user want to leave this option disabled to avoid long timeouts
        # when applications first resolve the none existing IPv6 address.
        nssmdns6 = false; # Default: false
        # Whether to use POINTTOPOINT interfaces.
        # Enabling this might make mDNS unreliable due to usually large latencies
        # with such links and opens a potential security hole by allowing mDNS access
        # from internet connections.
        allowPointToPoint = false; # Default: false
        # Specify the number of resource records to be cached per interface.
        # Use 0 to disable caching. Leaving it null defaults to 4096.
        cacheEntriesMax = null; # Default: null
        debug = false; # Default: false
        # Specify network interfaces that should be used by the avahi-daemon.
        # If null, all local interfaces except loopback and point-to-point will be used.
        allowInterfaces = null; # Default: null
        # Specify network interfaces that should be ignored by the avahi-daemon.
        # This option takes precedence over `allowInterfaces`.
        denyInterfaces = null; # Default: null
        # Whether to reflect incoming mDNS (Multicast DNS) requests to all allowed
        # network interfaces.
        reflector = false; # Default: false
        # Whether to enable wide-area service discovery.
        wideArea = true; # Default: true
        # Specify non-local domains to be browsed.
        browseDomains = [ ]; # Default: [ ]
        publish = {
          enable = true;
          # Whether to register mDNS address records for all local IP addresses.
          addresses = false; # Default: false
          # Whether to allow other hosts to browse the locally used domain name.
          domain = false; # Default: false
          # Whether to register a mDNS HINFO record, which contains info about
          # the local operating system and CPU.
          hinfo = false; # Default: false
          # Whether to publish user services.
          userServices = true; # Default: false
          # Whether to register a service of type "_workstation._tcp" on the local LAN.
          workstation = false; # Default: false
        };
        extraConfig = ""; # Default: ''
        extraServiceFiles = { }; # Default: { }
      };

      # Enable printing support through the CUPS (Common UNIX Printing System) daemon.
      printing = {
        enable = true;
        # Whether to open the firewall for TCP ports specified in `listenAddresses`.
        openFirewall = false; # Default: false
        # CUPSd's temporary directory.
        tempDir = "/tmp"; # Default: '/tmp'
        # Allow the machine for sharing local printers by default.
        defaultShared = true;
        # Specify the cupsd logging verbosity.
        logLevel = "info"; # Default: 'debug'
        # Allow unconditional access from all interfaces.
        allowFrom = [
          "all" # Default: "localhost"
        ];
        # Force the machine to listen on all interfaces and act as a print server
        # for other computers on the network.
        listenAddresses = [
          "*:631" # Default: "localhost:631"
        ];
        # Add CUPS driver packages here if needed.
        # Drivers provided by CUPS, cups-filters, Ghostscript and Samba are added
        # unconditionally.
        drivers = [ ]; # Default: [ ]
        # With this, Systemd will start CUPS on the first incoming connection
        # instead of having it permanently running as a daemon.
        startWhenNeeded = true;
        # Whether to remove all state directories related to CUPS on every startup of
        # the service.
        stateless = false; # Default: false
        # Whether to enable the web interface.
        webInterface = true; # Default: true
        # Add the client configurations to `client.conf`.
        clientConf = ""; # Default: ''
        # Add the CUPS Browsed configurations to `cups-browsed.conf`.
        browsedConf = ""; # Default: ''
        # Add the contents of `/etc/cups/snmp.conf`.
        snmpConf = ''
          Address @LOCAL
        ''; # Default: ''Address @LOCAL''
        # Add extra CUPSd configurations to `cupsd.conf`.
        extraConf = ""; # Default: ''
        # Add extra CUPSd file configurations to `cups-files.conf`.
        extraFilesConf = ""; # Default: ''
      };
    };

    # Need to manually open port 631 in the firewall so traffic from outside
    # can reach it.
    networking.firewall = {
      allowedUDPPorts = [ 631 ];
      allowedTCPPorts = [ 631 ];
    };

    yakumo.system.persistence.yosuga =
      let
        yosugaCfg = config.yakumo.system.persistence.yosuga;
      in
      mkIf yosugaCfg.enable {
        directories = [
          {
            path = "/var/lib/cups";
            mode = "0755";
          }
        ];
      };
  };
}
