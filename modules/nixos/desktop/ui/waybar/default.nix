{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
  cfg = config.yakumo.desktop.ui.waybar;
  jsonFormat = pkgs.formats.json { };
in {
  options.yakumo.desktop.ui.waybar = {
    enable = mkEnableOption "waybar";
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Waybar configuration in Nix-representable JSON format.
        For more details, see:
        https://github.com/Alexays/Waybar/wiki/Configuration
      '';
    };
    style = mkOption {
      type = types.nullOr (types.either types.path types.lines);
      default = null;
      description = ''
        CSS style of Waybar. For more details, see:
        https://github.com/Alexays/Waybar/wiki/Configuration
        If the value is set to a path literal, it will be regarded as the CSS file.
      '';
    };
    package = mkPackageOption pkgs "waybar" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Waybar package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (let
    inherit (builtins) isPath;
    inherit (lib) isStorePath getExe getName;
    inherit (pkgs) writeText;
    inherit (murakumo.wrappers) mkAppWrapper;

    waybarConfig = jsonFormat.generate "config.json" cfg.settings;
    waybarStyle = if isPath cfg.style || isStorePath cfg.style then
      cfg.style
    else
      writeText "style.css" cfg.style;
    waybarWrapped = mkAppWrapper {
      pkg = cfg.package;
      name = "${getName cfg.package}-${config.yakumo.user.name}";
      flags = [ "--config" waybarConfig "--style" waybarStyle ];
    };
  in {
    yakumo.desktop.ui.waybar.packageWrapped = waybarWrapped;
    yakumo.user.packages = [ waybarWrapped ];

    # Ensure to remove any manual exec commands written in compositors' configs
    # now that Systemd takes care of Waybar.
    systemd.user.services.waybar = {
      unitConfig = {
        After = [ "graphical-session.target" ];
        Description = "Waybar: Highly customizable Wayland bar for compositors";
        Documentation = "https://github.com/Alexays/Waybar/wiki";
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        # Allow reloading configuration without restarting the process
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        ExecStart = "${getExe waybarWrapped}";
        ExecStartPost = "${pkgs.coreutils}/bin/sleep 2";
        KillMode = "mixed";
        Restart = "on-failure";
      };
      wantedBy = [ "graphical-session.target" ];
    };
  });
}
