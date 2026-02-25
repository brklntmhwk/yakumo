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
<<<<<<< HEAD
      ++ [
        (pkgs.makeDesktopItem {
          name = "brave";
          desktopName = "Brave";
          genericName = "Web Browser";
          icon = "brave";
          exec = "${pkgs.brave}/bin/brave --incognito";
          categories = [ "Network" ];
        })
      ];
=======
      ++ [(pkgs.makeDesktopItem {
        name = "brave";
        desktopName = "Brave";
        genericName = "Web Browser";
        icon = "brave";
        exec = "${pkgs.brave}/bin/brave --incognito";
        categories = [ "Network" ];
      })];
>>>>>>> e7f9bb2 (fix: modify wrong syntax and remove wrong arg)
  };
}
