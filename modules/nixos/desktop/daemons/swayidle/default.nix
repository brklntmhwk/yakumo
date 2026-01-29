{
  config,
  lib,
  pkgs,
  murakumo,
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
  cfg = config.yakumo.desktop.daemons.swayidle;

  # https://github.com/nix-community/home-manager/commit/65e5b835a94b3bca9a1e219e5c43c1bc5fc04598
  timeoutSubmodule = types.submodule {
    options = {
      timeout = mkOption {
        type = types.ints.positive;
        description = "Timeout in seconds.";
      };
      command = mkOption {
        type = types.str;
        description = "Command to run when timeout is reached.";
      };
      resumeCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to run when activity resumes.";
      };
    };
  };

  eventSubmodule = types.submodule {
    options = {
      event = mkOption {
        type = types.enum [
          "after-resume"
          "before-sleep"
          "lock"
          "unlock"
        ];
        description = "Valid event name.";
      };
      command = mkOption {
        type = types.str;
        description = "Command to run when event occurs.";
      };
    };
  };
in
{
  options.yakumo.desktop.daemons.swayidle = {
    enable = mkEnableOption "swayidle";
    settings = mkOption {
      type = types.submodule {
        options = {
          timeouts = mkOption {
            type = types.listOf timeoutSubmodule;
            default = [ ];
            description = "List of timeout events.";
          };
          events = mkOption {
            type = types.listOf eventSubmodule;
            default = [ ];
            description = "List of event attributes.";
          };
        };
      };
      default = { };
      description = ''
        Swayidle configuration in Nix-representable format.
        For the valid setting options, see:
        https://man.archlinux.org/man/extra/swayidle/swayidle.1.en#EVENTS
      '';
    };
    package = mkPackageOption pkgs "swayidle" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Swayidle package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getExe getName;
      inherit (pkgs) writeText;
      inherit (murakumo.wrappers) mkAppWrapper;
      inherit (murakumo.generators) toSwayidleConf;

      swayidleConf = writeText "config" (toSwayidleConf {
        attrs = cfg.settings;
      });
      swayidleWrapped = mkAppWrapper {
        pkgs = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [
          "-w" # Wait for command to finish executing before continuing
          "-C"
          swayidleConf
        ];
      };
    in
    {
      yakumo.desktop.daemons.swayidle.packageWrapped = swayidleWrapped;
      yakumo.user.packages = [ swayidleWrapped ];

      systemd.user.services.swayidle = {
        unitConfig = {
          After = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Description = "Swayidle: Idle daemon for Wayland desktop";
          Documentation = "man:swayidle(1)";
          PartOf = [ "graphical-session.target" ];
        };
        serviceConfig = {
          ExecStart = "${getExe swayidleWrapped}";
          Restart = "on-failure";
          RestartSec = 1;
        };
        wantedBy = [ "graphical-session.target" ];
      };
    }
  );
}
