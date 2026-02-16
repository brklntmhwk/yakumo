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
  cfg = config.yakumo.desktop.ui.wofi;
in
{
  options.yakumo.desktop.ui.wofi = {
    enable = mkEnableOption "wofi";
    # https://github.com/nix-community/home-manager/commit/5160039edca28a7e66bad0cfc72a07c91d6768ad
    settings = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Wofi configuraion in Nix-representable config format.
        For more details, see: {manpage}`wofi(5)`.
      '';
    };
    style = mkOption {
      type = types.nullOr (types.either types.path types.lines);
      default = null;
      description = ''
        CSS style of Wofi. For more details, see:
        https://cloudninja.pw/docs/wofi.html
        If the value is set to a path literal, it will be regarded as the CSS file.
      '';
    };
    package = mkPackageOption pkgs "wofi" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Wofi package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (builtins) isPath;
      inherit (lib)
        filterAttrs
        getName
        generators
        isStorePath
        ;
      inherit (pkgs) writeText;
      inherit (murakumo.wrappers) mkAppWrapper;

      # https://github.com/nix-community/home-manager/commit/5160039edca28a7e66bad0cfc72a07c91d6768ad
      wofiConf = writeText "config" (
        generators.toKeyValue { } (filterAttrs (name: value: value != null) cfg.settings)
      );
      wofiStyle =
        if isPath cfg.style || isStorePath cfg.style then cfg.style else writeText "style.css" cfg.style;
      wofiWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        flags = [
          "--conf"
          wofiConf
          "--style"
          wofiStyle
        ];
      };
    in
    {
      yakumo.desktop.ui.wofi.packageWrapped = wofiWrapped;
      yakumo.user.packages = [ wofiWrapped ];
    }
  );
}
