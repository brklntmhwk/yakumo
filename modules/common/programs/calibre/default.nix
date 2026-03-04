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
  cfg = config.yakumo.programs.calibre;
in
{
  options.yakumo.programs.calibre = {
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
      inherit (builtins) length;
      inherit (lib) concatMapStringsSep getName;
      inherit (murakumo.wrappers) mkAppWrapper;

      pluginAddCmds = mkIf (length cfg.plugins > 0) (concatMapStringsSep "\n" (p: ''
        # Add Calibre plugins while suppressing output and allowing failure
        # so that it won't crash the launch even if a plugin is already installed.
        ${cfg.package}/bin/calibre-customize -a "${p}" >/dev/null 2>&1 || true
      '') cfg.plugins);
      calibreWrapped = mkAppWrapper {
        pkg = cfg.package;
        name = "${getName cfg.package}-${config.yakumo.user.name}";
        preWrapProgram = pluginAddCmds;
      };
    in
    {
      yakumo.programs.calibre.packageWrapped = calibreWrapped;
      yakumo.user.packages = [ calibreWrapped ];
    }
  );
}
