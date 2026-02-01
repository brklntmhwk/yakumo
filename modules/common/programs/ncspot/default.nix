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
  cfg = config.yakumo.programs.ncspot;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.yakumo.programs.ncspot = {
    enable = mkEnableOption "ncspot";
    # https://github.com/nix-community/home-manager/commit/2f857761d0506d3c4c51455aafb1df5180ad7e34
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Ncspot configuraion in Nix-representable TOML format.
        For more details, see:
        https://github.com/hrkfdn/ncspot/blob/main/doc/users.md#configuration
      '';
      example = lib.literalExpression ''
        {
          shuffle = true;
          gapless = true;
        }
      '';
    };
    package = mkPackageOption pkgs "ncspot" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Ncspot package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (lib) getName;
      inherit (murakumo.wrappers) mkAppWrapper;

      configToml = tomlFormat.generate "config.toml" cfg.settings;
      ncspotWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [
          "--config"
          configToml
        ];
      };
    in
    {
      yakumo.programs.ncspot.packageWrapped = ncspotWrapped;
      yakumo.user.packages = [ ncspotWrapped ];
    }
  );
}
