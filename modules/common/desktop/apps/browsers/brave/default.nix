{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.yakumo.desktop.apps.browsers.brave;
in
{
  options.yakumo.desktop.apps.browsers.brave = {
    enable = mkEnableOption "brave";
  };

  config = mkIf cfg.enable {
    yakumo.user.packages =
      builtins.attrValues {
        inherit (pkgs) brave;
      }
      ++ (pkgs.makeDesktopItem {
        name = "brave";
        desktopName = "Brave";
        description = "Brave Browser.";
        genericName = "Web Browser";
        icon = "brave";
        exec = "${pkgs.brave}/bin/brave --incognito";
        categories = [ "Network" ];
      });
  };
}
