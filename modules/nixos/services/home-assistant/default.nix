# WIP
{
  config,
  lib,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.home-assistant;
  meta = config.yakumo.services.metadata.home-assistant;
in
{
  options.yakumo.services.home-assistant = {
    enable = mkEnableOption "home-assistant";
  };

  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      openFirewall = false; # Default: false
      configDir = "/var/lib/hass"; # Default: '/var/lib/hass'
      # Allow mutable config editing via HA's web UI if set to true.
      # This only has an effect if the config option is set.
      # Note that those mutable changes will be wiped out at every start of the service.
      configWritable = false; # Default: false
      config = {
        default_config = { };
        homeassistant = {
          name = "Home";
          external_url = "https://${meta.domain}";
          internal_url = "https://${meta.domain}";
          latitude = "!secret latitude";
          longitude = "!secret longitude";
          elevation = "!secret elevation";
          unit_system = "metric";
          time_zone = "UTC";
          packages.manual = "!include manual.yaml";
        };
        http = {
          server_port = meta.port;
          trusted_proxies = [ ];
          # use_x_forwarded_for = true;
        };
      };
      # For the available components, see `pkgs.home-assistant-custom-components`.
      customComponents = [ ];
      defaultIntegrations = [
        "application_credentials"
        "frontend"
        "hardware"
        "logger"
        "network"
        "system_health"
        "automation"
        "person"
        "scene"
        "script"
        "tag"
        "zone"
        "counter"
        "input_boolean"
        "input_button"
        "input_datetime"
        "input_number"
        "input_select"
        "input_text"
        "schedule"
        "timer"
        "backup"
      ];
      extraArgs = [ ];
      # https://www.home-assistant.io/integrations/?brands=featured
      extraComponents = [
        # Defaults
        "default_config"
        "met"
        "esphome"
        # Customs
        "forecast_solar"
        "mqtt"
        "spotify"
        "wake_word"
        "whisper"
        "wyoming"
      ];
      # Specify additional packages to add to `propagatedBuildInputs`.
      extraPackages = [ ];
      blueprints = {
        automation = [ ];
        script = [ ];
        template = [ ];
      };
      # For the available components, see `pkgs.home-assistant-custom-lovelace-modules`.
      customLovelaceModules = [ ];
      lovelaceConfig = null; # Default: null
      lovelaceConfigFile = null; # Default: null
      lovelaceConfigWritable = false; # Default: false
    };

    yakumo =
      let
        rusticCfg = config.yakumo.services.rustic;
        hassCfg = config.services.home-assistant;
      in
      mkMerge [
        {
          services.metadata.home-assistant.reverseProxy = {
            caddyIntegration.enable = true;
          };
        }
        (mkIf rusticCfg.enable {
          services.rustic.backups = {
            home-assistant = {
              environmentFile = config.sops.secrets."hass/rustic_env_file".path;
              timerConfig = {
                OnCalendar = "*-*-* 04:00:00"; # Run daily at 4 a.m.
                Persistent = true;
              };
              settings = {
                repository = "s3:https://your-s3-endpoint/bucket/home-assistant";
                backup = {
                  sources = [
                    hassCfg.configDir
                  ];
                  # Exclude the high-churn SQLite WAL and SHM files to prevent
                  # backup errors.
                  exclude = [
                    "home-assistant_v2.db-shm"
                    "home-assistant_v2.db-wal"
                  ];
                };
                forget = {
                  keep-daily = 7;
                  keep-weekly = 4;
                  prune = true;
                };
              };
            };
          };
        })
      ];

    sops.secrets = {
      "hass/rustic_env_file" = {
        sopsFile = rootPath + "/secrets/default.yaml";
      };
    };
  };
}
