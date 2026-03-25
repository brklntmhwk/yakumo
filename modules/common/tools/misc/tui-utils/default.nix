{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.yakumo.tools.misc.tui-utils;
in
{
  options.yakumo.tools.misc.tui-utils = {
    enable = mkEnableOption "TUI utilities";
  };

  config = mkIf cfg.enable {
    yakumo.user.packages = builtins.attrValues {
      # Install util TUIs altogether that you don't need to wrap with their configurations.
      inherit (pkgs)
        bandwhich # Terminal bandwidth util
        ;
    };
  };
}
