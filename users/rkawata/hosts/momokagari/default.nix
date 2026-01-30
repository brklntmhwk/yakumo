{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib) catAttrs;
  inherit (theme) cursorThemes fonts loginThemes;
  theme = import ../../themes/modus-operandi-tinted;
in
{
  imports = [
    ../common # Common configs among user's hosts
  ];

  yakumo.desktop = {
    enable = true;
    terminal = {
      wezterm = {
        enable = true;
        # settings = import ./configs/wezterm { };
      };
    };
    apps = {
      media = {
        modules = [
          "music"
          "video/davinci-resolve"
        ];
      };
    };
  };
}
