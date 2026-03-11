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
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.desktop.daemons.hypridle;
in
{
  options.yakumo.desktop.daemons.hypridle = {
    enable = mkEnableOption "hypridle";
    # https://github.com/nix-community/home-manager/commit/ee5673246de0254186e469935909e821b8f4ec15
    settings = mkOption {
      type =
        let
          valType =
            types.nullOr (
              types.oneOf [
                types.bool
                types.float
                types.int
                types.path
                types.str
                (types.attrsOf valType)
                (types.listOf valType)
              ]
            )
            // {
              description = "Hypridle configuration values in Nix-representable Hyprconf format.";
            };
        in
        valType;
      default = { };
      description = ''
        Hypridle configuraion in Nix-representable Hyprconf format.
      '';
    };
    package = mkPackageOption pkgs "hypridle" { };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = config.yakumo.desktop.compositors.hyprland.enable;
          message = "Hypridle requires Hyprland as a Wayland compositor";
        }
      ];
    }
    (
      let
        inherit (lib) getExe;
        inherit (pkgs) writeText;
        inherit (murakumo.generators) toHyprconf;

        hypridleConf = writeText "hypridle.conf" (toHyprconf {
          attrs = cfg.settings;
        });
      in
      {
        yakumo.user.packages = [ cfg.package ];

        systemd.user.services.hypridle = {
          unitConfig = {
            After = [ "hyprland-session.target" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "Hypridle: Idle daemon for Hyprland.";
            PartOf = [ "hyprland-session.target" ];
          };
          serviceConfig = {
            ExecStart = "${getExe cfg.package} --config ${hypridleConf}";
            Restart = "on-failure";
            RestartSec = 1;
          };
          wantedBy = [ "hyprland-session.target" ];
        };
      }
    )
  ]);
}
