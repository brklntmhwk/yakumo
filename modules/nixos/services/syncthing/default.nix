# WIP
{
  config,
  lib,
  murakumo,
  rootMeta,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.syncthing;
  meta = config.yakumo.services.metadata.syncthing;
in
{
  options.yakumo.services.syncthing = {
    enable = mkEnableOption "syncthing";
    relay = {
      enable = mkEnableOption "syncthing relaying";
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (meta) address bindAddress extraPorts;
      inherit (config.services.syncthing) configDir dataDir group user relay;
    in
    mkMerge [
      {
        assertions =
          let
            inherit (murakumo.assertions) assertServiceUp;
          in
          [
            (assertServiceUp "syncthing" rootMeta.allServices)
          ];

        services.syncthing = {
          enable = true;
          group = "syncthing"; # Default: 'syncthing'
          user = "syncthing"; # Default: 'syncthing'
          # Overwrite the all_proxy env variable for the Syncthing process.
          all_proxy = null; # Default: null
          # The device's ECDSA public and private key.
          # These will be copied into Syncthing's configDir.
          # We don't rely on ACME here, because:
          # - ACME certificates automatically rotate at designated intervals.
          # - Syncthing's Device ID is mathematically tied to its TLS certificate.
          # - If the certificate changes, the Device ID changes.
          # - Every time the cert rotates, the machine gets a brand-new Device ID,
          # and then all others will drop the connection, regarding it as a rogue,
          # untrusted device.
          # Specify the path to the 'cert.pem' file.
          cert = config.sops.secrets."syncthing/tls_cert".path; # Default: null
          # Specify the path to the 'key.pem' file.
          key = config.sops.secrets."syncthing/tls_key".path; # Default: null
          # Specify the address to serve the web UI at.
          guiAddress = bindAddress;
          guiPasswordFile = config.sops.secrets."syncthing/gui_passwd_file".path; # Default: null
          # Default: `config.services.syncthing.dataDir` (if `system.stateVersion` >= '19.03')
          configDir = dataDir;
          dataDir = "/var/lib/syncthing"; # Default: '/var/lib/syncthing'
          # The DB dir contains the following files:
          # - 'index-*': The DB with metadata and hashes of the files currently
          # on disk and available from peers.
          # - 'syncthing.log': Log output, on some systems.
          # - 'audit-*.log': Audit log data, when enabled.
          # - 'panic-*.log': Crash log data, when required.
          # https://docs.syncthing.net/users/config.html#description
          databaseDir = configDir; # Default: `config.services.syncthing.configDir`
          # Extra flags passed to the syncthing command in the service definition.
          extraFlags = [ ];
          # Delete the devices that are not configured via the devices option.
          # If set to false, devices added via the web UI will persist and
          # have to be deleted manually.
          overrideDevices = true; # Default: true
          # The folder version of the overrideDevices option above.
          overrideFolders = true; # Default: true, unless any device has the autoAcceptFolders option.
          # Open the default ports in the firewall:
          # TCP/UDP 22000 for transfers and UDP 21027 for discovery.
          # Enabling this will add them to `allowedTCPPorts` & `allowedUDPPorts` in
          # the `networking.firewall` option, respectively.
          # If multiple users are running Syncthing on this machine,
          # you will need to manually open a set of ports for each instance and
          # leave this disabled.
          # Alternatively, if you are running only a single instance on this machine
          # using the default ports, enable this.
          openDefaultPorts = true; # Default: false
          # Auto-launch Syncthing as a system service.
          systemService = true; # Default: true
          # Relaying will only be used if two devices are unable to communicate
          # directly with each other.
          # Keep in mind that the transfer rate is much lower than a direct connection.
          # https://docs.syncthing.net/users/relaying.html
          # https://docs.syncthing.net/users/strelaysrv.html#strelaysrv
          relay = {
            # Whether to enable the Syncthing relay systemd service.
            inherit (cfg.relay) enable; # Default: false
            listenAddress = address; # Default: ''
            statusListenAddress = address; # Default: ''
            port = extraPorts.relay; # Default: 22067
            statusPort = extraPorts.relay; # Default: 22067
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
            # The required `id` and `path` props default to the attribute name.
            # https://docs.syncthing.net/users/config.html#device-element
            devices = { };
            # The required `id` and `path` props default to the attribute name.
            # https://docs.syncthing.net/users/config.html#folder-element
            folders = { };
            # https://docs.syncthing.net/users/config.html
            options = {
              # Whether to send crash reports automatically to the Syncthing developers.
              crashReportingEnabled = false;
              # Apply bandwidth limits to devices in the same broadcast domain
              # as the local device if set to true.
              limitBandwidthInLan = false; # Default: null
              # Send announcements to the local LAN and use them to find
              # other devices if set to true.
              localAnnounceEnabled = false; # Default: null
              # The port on which to listen and send IPv4 broadcast announcements to.
              localAnnouncePort = null; # Default: null
              # Control how many folders may concurrently be in I/O-intensive operations
              # such as syncing or scanning.
              # Options:
              # - 0 (The number of logical CPUs in the system)
              # - <0 (No limit on the number of concurrent operations)
              # - >0 (Use this specific limit)
              # https://docs.syncthing.net/advanced/option-max-concurrency.html
              maxFolderConcurrency = 0; # Default: null
              relaysEnabled = cfg.relay.enable; # Default: null
              # Let the user accept to submit anonymous usage data if set to integer
              # above zero. UR stands for usage reporting.
              # Options:
              # - 0 (Undecided and will be asked at some point in the future)
              # - -1 (No)
              urAccepted = -1; # Default: null (equivalent to 1)
            };
          };
        };

        networking.firewall = {
          allowedTCPPorts = mkIf relay.enable builtins.attrValues {
            inherit (relay) port statusPort;
          };
        };

        yakumo =
          let
            inherit (lib) optionals;
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            (mkIf yosugaCfg.enable {
              system.persistence.yosuga = {
                directories = [
                  {
                    inherit group user;
                    path = dataDir;
                    mode = "0750";
                  }
                ]
                ++ optionals relay.enable [
                  # https://github.com/NixOS/nixpkgs/blob/ed142ab1b3a092c4d149245d0c4126a5d7ea00b0/nixos/modules/services/networking/syncthing-relay.nix
                  {
                    path = "/var/lib/private/syncthing-relay";
                    mode = "0700";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          "syncthing/gui_passwd_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "syncthing";
          };
          "syncthing/tls_cert" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "syncthing";
          };
          "syncthing/tls_key" = {
            sopsFile = rootPath + "/secrets/default.yaml";
            owner = "syncthing";
          };
        };
      }
    ]
  );
}
