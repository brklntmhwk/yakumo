{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.yakumo.tools.browsers.brave;
in
{
  options.yakumo.tools.browsers.brave = {
    enable = mkEnableOption "brave";
  };

  config = mkIf cfg.enable {
    yakumo.user.packages =
      builtins.attrValues {
        inherit (pkgs) brave;
      }
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
  };
}
