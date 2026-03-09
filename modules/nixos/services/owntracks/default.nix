# WIP
# Based on:
# https://github.com/JakobLichterfeld/nix-config/blob/765ea542b9982b6171bcf6f0701bdc330164a754/homelab/services/owntracks-recorder/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.services.owntracks;
  meta = config.yakumo.services.metadata.owntracks;
  mqttBrokers = [
    "mosquitto"
    "rmqtt"
  ];
in
{
  options.yakumo.services.owntracks = {
    enable = mkEnableOption "owntracks-recorder";
    stateDir = mkOption {
      type = types.path;
      description = "Directory containing the persistent state data to back up.";
      default = "/var/lib/owntracks-recorder";
    };
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "File containing environment variables.";
    };
    mqttIntegration = {
      enable = mkEnableOption "MQTT integration for OwnTracks Recorder";
      broker = mkOption {
        type = types.enum mqttBrokers;
        default = "mosquitto";
        description = "MQTT broker to use.";
        example = "rmqtt";
      };
      topic = mkOption {
        type = types.str;
        default = "owntracks/#";
        description = "MQTT topic(s) the recorder should subscribe to.";
      };
    };
    frontend = {
      enable = mkEnableOption "owntracks-frontend";
      config = mkOption {
        type = types.either types.lines types.path;
        default = "";
        description = ''
          OwnTracks Frontend configuration written in JavaScript.
        '';
        example = ''
          window.owntracks = window.owntracks || {};
          window.owntracks.config = {};
        '';
      };
      package = mkPackageOption pkgs "owntracks-frontend" { };
    };
    package = mkPackageOption pkgs "owntracks-recorder" { };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) isPath isStorePath toString;
      inherit (lib)
        mkForce
        mkMerge
        optional
        optionalAttrs
        ;
      inherit (pkgs) runCommand writeText;

      mqttCfg = config.yakumo.services.owntracks.mqttIntegration;

      configFile =
        if isPath cfg.frontend.config || isStorePath cfg.frontend.config then
          cfg.frontend.config
        else
          writeText "config.js" cfg.frontend.config;
      configDir = runCommand "owntracks-frontend-config" { } ''
        mkdir -p $out/config
        cp ${configFile} $out/config/config.js
      '';
    in
    {
      assertions = [
        (optionalAttrs mqttCfg.enable {
          assertion = (mqttCfg.broker == "mosquitto") -> config.yakumo.services.mosquitto.enable;
          message = "Mosquitto must be enabled for MQTT integration if used as a broker";
        })
      ];

      environment.systemPackages = [ cfg.package ] ++ optional cfg.frontend.enable cfg.frontend.package;

      users.groups.owntracks = { };
      users.users.owntracks = {
        isSystemUser = true;
        description = "OwnTracks service user.";
        group = "owntracks";
        createHome = mkForce false;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.stateDir} 0750 owntracks owntracks - -"
        "Z ${cfg.stateDir} 0750 owntracks owntracks - -"
      ];

      systemd.services."owntracks-recorder" = {
        description = "OwnTracks Recorder: Store and access data published by OwnTracks apps.";
        after = [
          "network-online.target"
        ]
        ++ optional mqttCfg.enable (
          if (mqttCfg.broker == "mosquitto") then
            [
              "mosquitto.service"
            ]
          else
            [ "rmqtt.service" ]
        );
        requires = optional mqttCfg.enable (
          if (mqttCfg.broker == "mosquitto") then
            [
              "mosquitto.service"
            ]
          else
            [ "rmqtt.service" ]
        );
        environment = mkMerge [
          {
            OTR_STORAGEDIR = cfg.stateDir;
            OTR_HTTPLOGDIR = cfg.stateDir;
            OTR_HTTPHOST = meta.address;
            OTR_HTTPPORT = toString meta.port;
            # The higher the number, the more frequently lookups are performed.
            # e.g., If set to 1, points within an area of approximately 5000 km^2
            # would resolve to a single address compared to 150 m^2 with precision 7.
            # For the details, see:
            # https://github.com/owntracks/recorder?tab=readme-ov-file#precision
            OTR_PRECISION = "7";
            # Set this to 0 to disable MQTT.
            OTR_PORT = mkIf (!mqttCfg.enable) "0";
          }
          (mkIf mqttCfg.enable (
            let
              # TODO: Make this conditional after adding Rmqtt.
              mqttSrvMetadata = config.yakumo.services.metadata.mosquitto;
            in
            {
              OTR_HOST = mqttSrvMetadata.host;
              OTR_PORT = toString mqttSrvMetadata.port;
            }
          ))
        ];
        serviceConfig = {
          User = "owntracks";
          Restart = "on-failure";
          RestartSec = 5;
          WorkingDirectory = cfg.stateDir;
          # Topic is always required even if MQTT is not enabled.
          ExecStart = "${cfg.package}/bin/ot-recorder --storage ${cfg.stateDir} ${mqttCfg.topic}";
          EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ]; # IPv4 + IPv6 only.
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ cfg.stateDir ];
        };
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };

      services.caddy.virtualHosts."${meta.domain}" = {
        # Specify a host of an existing Let's Encrypt certificate.
        # Useful if we use DNS challenges but Caddy doesn't support our DNS provider.
        useACMEHost = "yakumo.com";

        # Have Caddy handling the config file instead of relying on the package
        # override (i.e., `pkgs.foo.override`), as it will trigger a full rebuild of
        # the Node.js package every time the user changes a single setting in `config.js`.
        extraConfig =
          if cfg.frontend.enable then
            ''
              handle /config/config.js {
                root * ${configDir}
                file_server
              }
              handle /pub* {
                reverse_proxy ${meta.bindAddress}
              }
              handle /api* {
                reverse_proxy ${meta.bindAddress}
              }
              handle /ws* {
                reverse_proxy ${meta.bindAddress}
              }
              handle /recorder* {
                reverse_proxy ${meta.bindAddress}
              }
              handle {
                root * ${cfg.frontend.package}/share
                file_server
              }
            ''
          else
            ''
              reverse_proxy ${meta.bindAddress}
            '';
      };
    }
  );
}
