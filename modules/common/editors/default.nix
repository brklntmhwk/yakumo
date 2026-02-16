{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.yakumo.editors;
in
{
  options.yakumo.editors = {
    default = mkOption {
      type = types.str;
      default = "nano";
    };
  };

  config = mkIf (cfg.default != null) { environment.variables.EDITOR = cfg.default; };
}
