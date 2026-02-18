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
  cfg = config.yakumo.desktop.lockers.hyprlock;
in
{
  options.yakumo.desktop.lockers.hyprlock = {
    enable = mkEnableOption "hyprlock";
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
              description = "Hyprlock configuration values in Nix-representable Hyprconf format.";
            };
        in
        valType;
      default = { };
      description = ''
        Hyprlock configuraion in Nix-representable Hyprconf format.
      '';
    };
    package = mkPackageOption pkgs "hyprlock" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Hyprlock package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getName;
      inherit (pkgs) writeText;
      inherit (murakumo.wrappers) mkAppWrapper;
      inherit (murakumo.generators) toHyprconf;

      hyprlockConf = writeText "hyprlock.conf" (toHyprconf {
        attrs = cfg.settings;
      });
      hyprlockWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [
          "--config"
          hyprlockConf
        ];
      };
    in
    {
      yakumo.desktop.lockers.hyprlock.packageWrapped = hyprlockWrapped;
      environment.systemPackages = [ hyprlockWrapped ];

      # Enable PAM access for authentication.
      security.pam.services.hyprlock = { };
    }
  );
}
