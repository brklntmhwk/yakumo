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
  cfg = config.yakumo.tools.misc.ncspot;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.yakumo.tools.misc.ncspot = {
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
      inherit (murakumo.wrappers) mkWrapper;

      configToml = tomlFormat.generate "config.toml" cfg.settings;
      ncspotWrapped = mkWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        prependFlags = [
          "--config"
          configToml
        ];
      };
    in
    {
      yakumo.tools.misc.ncspot.packageWrapped = ncspotWrapped;
      yakumo.user.packages = [ ncspotWrapped ];
    }
  );
}
