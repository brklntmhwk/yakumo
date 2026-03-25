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
  cfg = config.yakumo.tools.misc.calibre;
in
{
  options.yakumo.tools.misc.calibre = {
    enable = mkEnableOption "calibre";
    plugins = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "List of Calibre plugins to install.";
    };
    package = mkPackageOption pkgs "calibre" { };
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
      inherit (builtins) length map;
      inherit (lib) concatMapStringsSep getName;
      inherit (murakumo.wrappers) mkWrapper;

      # Add Calibre plugins while suppressing output and allowing failure
      # so that it won't crash the launch even if a plugin is already installed.
      pluginAddCmds = map (p: ''
        ${cfg.package}/bin/calibre-customize -a "${p}" >/dev/null 2>&1 || true
      '') cfg.plugins;

      calibreWrapped = mkWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        preCommands = pluginAddCmds;
      };

      finalPackage = if (length cfg.plugins > 0) then calibreWrapped else cfg.package;
    in
    {
      yakumo.tools.misc.calibre.packageWrapped = finalPackage;
      yakumo.user.packages = [ finalPackage ];
    }
  );
}
