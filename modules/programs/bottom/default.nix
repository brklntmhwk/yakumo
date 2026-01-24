{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.yakumo.programs.bottom;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.yakumo.programs.bottom = {
    enable = mkEnableOption "bottom";
    # https://github.com/nix-community/home-manager/commit/4b964d2f7baca30655ac0780d3003eeb5a4929f0
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Bottom configuraion in Nix-representable TOML format.
        For more details, see:
        https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml
      '';
      example = literalExpression ''
        {
          flags = {
            avg_cpu = true;
            temperature_type = "c";
          };

          colors = {
            low_battery_color = "red";
          };
        }
      '';
    };
    package = mkPackageOption pkgs "bottom" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Bottom package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getName;
      inherit (murakumo.wrappers) mkAppWrapper;

      bottomToml = tomlFormat.generate "bottom.toml" cfg.settings;
      bottomWrapped = mkAppWrapper {
        pkgs = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [
          "--config_location"
          bottomToml
        ];
      };
    in
    {
      yakumo.programs.bottom.packageWrapped = bottomWrapped;
      yakumo.user.packages = [ bottomWrapped ];
    }
  );
}
