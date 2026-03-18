# WIP
{
  config,
  lib,
  flakeRoot,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.services.samba;
in
{
  options.yakumo.services.samba = {
    enable = mkEnableOption "samba";
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      # This adds
      openFirewall = true; # Default: false
      # Enable WINS NSS (Name Service Switch) plugin if set to true.
      # Doing so allows apps to resolve WINS/NetBIOS names
      # (a.k.a. Windows machine names) by transparently querying the winbindd daemon.
      nsswins = false; # Default: false
      # NetBIOS Name Service Daemon: replies to NetBIOS over IP name service requests.
      nmbd = {
        enable = true; # Default: true
        extraArgs = [ ];
      };
      # SMB Daemon: provides file-sharing and printing services for Windows clients.
      smbd = {
        enable = true; # Default: true
        extraArgs = [ ];
      };
      usershares = {
        enable = false; # Default: false
        group = "samba"; # Default: 'samba'
      };
      # Name Service Switch Daemon: provides a number of services for the Name Service
      # Switch capability found in most modern C libraries.
      winbindd = {
        enable = false; # Default: true
        extraArgs = [ ];
      };
      # https://man.archlinux.org/man/smb.conf.5
      settings = {
        global = {
          # Set this to a small number to stop a server's resources being exhausted
          # by a large number of inactive connections (minutes).
          # After this period of inactive time, it gets disconnected.
          "deadtime" = "60"; # Default: '10080'
          "server string" = "Samba";
          # Options: 'standalone', 'member server', 'domain controller'
          "server role" = "standalone"; # Default: 'auto'
          # Set the minimum protocol version to Windows 10 SMB3 version.
          "server min protocol" = "SMB3_11"; # Default: 'SMB2_02' (The earliest SMB2 version)
          # Enable negotiation and turn on data encryption on sessions and share connections.
          # Clients without support for encryption will be denied access to the server.
          "server smb encrypt" = "required"; # Default: 'default'
          "netbios name" = "Samba";
          # Disable NetBIOS support.
          # NetBIOS is the only available form of browsing in Windows versions
          # prior to Windows 2000.
          "disable netbios" = "yes"; # Default: 'no'
          # Disable Samba's support for the SPOOLSS set of MS-RPC's.
          "disable spoolss " = "yes"; # Default: 'no'
          # Deny access from all hosts by default.
          # The 'hosts allow' param will take precedence.
          "hosts deny" = "0.0.0.0/0";
          # Permit access from these hosts.
          "hosts allow" = [ ];
          "guest account" = "nobody"; # Default: 'nobody'
          # Reject all user login requests with an invalid password.
          "map to guest" = "Never"; # Default: 'Never'
          "invalid users" = [
            "root"
          ];
          "passdb backend" = "tdbsam:${config.sops.secrets.samba_passdb.path}"; # Default: 'tdbsam'
          "security" = "user"; # Default: 'user' (Options: 'auto', 'domain', 'ads')
          # Make the share visible only to users with the R&W access permissions
          # to the share during share enumeration.
          "access based share enum" = "yes";
          # Set the logging backend to Systemd.
          # Options: 'syslog', 'file', 'lttng', 'gpfs', 'ringbuf'
          "logging" = "systemd";
          # Specify the debug level. Per-class specification is supported.
          "log level" = "0 passdb:2 auth:2"; # Default: '0'
          # Override the name of the Samba log file (the debug file).
          "log file" = "/dev/null";
          # Specify the max size the log file should grow to.
          # A size of 0 means no limit.
          "max log size" = "0"; # Default: '5000' (kilibytes)
        };
      };
    };

    sops.secrets = {
      samba_passdb = {
        sopsFile = flakeRoot + "/secrets/default.yaml";
      };
    };
  };
}
