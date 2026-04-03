# WIP
{
  config,
  lib,
  murakumo,
  rootMeta,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.mosquitto;
  meta = config.yakumo.services.metadata.mosquitto;
in
{
  options.yakumo.services.mosquitto = {
    enable = mkEnableOption "mosquitto";
  };

  config = mkIf cfg.enable {
    assertions =
      let
        inherit (murakumo.assertions) assertServiceUp;
      in
      [
        (assertServiceUp "mosquitto" rootMeta.allServices)
      ];

    services.mosquitto = {
      enable = true;
      dataDir = "/var/lib/mosquitto";
      includeDirs = [ ];
      # Add destinations of log messages.
      # (Options: 'stdout', 'stderr', 'syslog', 'topic', 'dlt')
      logDest = [
        "stderr"
      ];
      # Add types of messages to log.
      # (Options: 'debug', 'error', 'warning', 'notice', 'information', 'subscribe',
      # 'unsubscribe', 'websockets', 'none', 'all')
      logType = [

      ]; # Default: [ ]
      # Enable persistent storage of subscriptions and messages.
      persistence = true; # Default: true
      bridges = { };
      listeners = [
        {
          inherit (meta) address port;
          users = {
            # Home Assistant
            # Make it align with the upstream home-assistant module.
            hass = {
              acl = [ "readwrite #" ];
              hashedPasswordFile = config.sops.secrets.mosquitto_hass_passwd.path; # Default: null
            };
          };
          omitPasswordAuth = false; # Default: false
          settings = {
            allow_anonymous = true;
          };
        }
      ];
      settings = { };
    };

    yakumo =
      let
        yosugaCfg = config.yakumo.system.persistence.yosuga;
      in
      mkMerge [
        (mkIf yosugaCfg.enable {
          system.persistence.yosuga = {
            directories = [
              {
                path = config.services.mosquitto.dataDir;
                mode = "0700";
              }
            ];
          };
        })
      ];
  };
}
