{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.programs.tui-utils;
in
{
  options.yakumo.programs.tui-utils = {
    enable = mkEnableOption "TUI utilities";
  };

  config = mkIf cfg.enable {
    yakumo.user.packages = builtins.AttrValues {
      # Install util TUIs altogether that you don't need to wrap with their configurations.
      inherit (pkgs)
        bandwhich # Terminal bandwidth util
        television # General purpose fuzzy finder TUI
        wthrr # Weather companion for the terminal
        ;
    };
  };
}
