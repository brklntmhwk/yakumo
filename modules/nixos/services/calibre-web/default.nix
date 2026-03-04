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
    mkOption
    types
    ;
  cfg = config.yakumo.services.calibre-web;
in
{
  options.yakumo.services.calibre-web = {
    enable = mkEnableOption "calibre-web";
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Domain name.";
    };
  };

  config = mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      group = "calibre-web"; # Default: 'calibre-web'
      user = "calibre-web"; # Default: 'calibre-web'
      # Note that this will be concatenated with '/var/lib/' if not specified
      # as an absolute path (e.g., '/path/to/calibre-web-data').
      dataDir = "calibre-web";
      openFirewall = false; # Default: false
      listen = {
        ip = "::1"; # Default: '::1'
        port = 8083; # Default: 8083
      };
      options = {
        # Path to Calibre library.
        calibreLibrary = null; # Default: null
        enableBookConversion = true; # Default: false
        enableBookUploading = true; # Default: false
        enableKepubify = false; # Default: false
        reverseProxyAuth = {
          enable = true; # Default: false
          header = ""; # Default: ''
        };
      };
    };

    services.caddy.virtualHosts = (
      let
        calibWebCfg = config.services.calibre-web;
      in
      {
        "${cfg.domain}" = {
          useACMEHost = "yakumo.net";
          extraConfig = ''
            reverse_proxy ${calibWebCfg.listen.ip}:${builtins.toString calibWebCfg.listen.port}
          '';
        };
      }
    );
  };
}
