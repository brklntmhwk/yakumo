# WIP
{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.services.syncthing;
in
{
  options.yakumo.services.syncthing = {
    enable = mkEnableOption "syncthing";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      group = "syncthing"; # Default: 'syncthing'
      user = "syncthing"; # Default: 'syncthing'
      # Overwrite the all_proxy env variable for the Syncthing process.
      all_proxy = "socks5://address.com:1234"; # Default: null
      # Specify the path to the `cert.pem` file.
      # This will be copied into Syncthing's configDir.
      cert = "path/to/cert-pem-file"; # Default: null
      # Specify the path to the `key.pem` file.
      # This will be copied into Syncthing's configDir.
      key = "path/to/key-pem-file"; # Default: null
      configDir = "";
      dataDir = "/var/lib/syncthing";
      databaseDir = "";
      extraFlags = [ ];
      guiAddress = "127.0.0.1:8384";
      guiPasswordFile = config.sops.secrets.xxx.path; # Default: null
      # Delete the devices that are not configured via the devices option.
      # If set to false, devices added via the web UI will persist and
      # have to be deleted manually.
      overrideDevices = true; # Default: true
      # The folder version of the overrideDevices option above.
      overrideFolders = true; # Default: true, unless any device has the autoAcceptFolders option.
      # Open the default ports in the firewall:
      # TCP/UDP 22000 for transfers and UDP 21027 for discovery.
      # If multiple users are running Syncthing on this machine,
      # you will need to manually open a set of ports for each instance and
      # leave this disabled.
      # Alternatively, if you are running only a single instance on this machine
      # using the default ports, enable this.
      openDefaultPorts = false; # Default: false
      # Auto-launch Syncthing as a system service.
      systemService = true; # Default: true
      relay = {
        enable = true;
        listenAddress = "";
        statusListenAddress = "";
        port = 22067; # Default: 22067
        statusPort = 22067; # Default: 22067
        # Specify extra args to pass to strelaysrv.
        extraOptions = [ ];
        # Global bandwidth rate limit in bytes per second.
        globalRateBps = null; # Default: null
        # Per session bandwidth rate limit in bytes per second.
        perSessionRateBps = null; # Default: null
        # Specify relay pools to join. If set to null, the default global pool
        # will be used.
        pools = null; # Default: null
        # Add description of the provider of the relay.
        providedBy = ""; # Default: ''
      };
      settings = {
        devices = { };
        folders = { };
        options = {
          # Apply bandwidth limits to devices in the same broadcast domain
          # as the local device if set to true.
          limitBandwidthInLan = null; # Default: null
          # Send announcements to the local LAN and use them to find
          # other devices if set to true.
          localAnnounceEnabled = null; # Default: null
          localAnnouncePort = null; # Default: null
          # Control how many folders may concurrently be in I/O-intensive operations
          # such as syncing or scanning.
          # Options:
          # - 0 (The number of logical CPUs in the system)
          # - <0 (No limit on the number of concurrent operations)
          # - >0 (Use this specific limit)
          maxFolderConcurrency = null; # Default: null
          relaysEnabled = null; # Default: null
          # Let the user accept to submit anonymous usage data if set to integer
          # above zero.
          # Options:
          # - 0 (Undecided and will be asked at some point in the future)
          # - -1 (No)
          urAccepted = null; # Default: null (equivalent to 1)
        };
      };
    };
  };
}
