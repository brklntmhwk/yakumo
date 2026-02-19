{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues isAttrs;
  inherit (lib)
    elem
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (murakumo.utils) anyAttrs countAttrs;
  cfg = config.yakumo.desktop;
in
{
  options.yakumo.desktop = {
    enable = mkEnableOption "desktop environment";
  };

  config = mkMerge [
    {
      # https://github.com/hlissner/dotfiles/commit/713cc540a72a2c4988e0757bbf4712c2d1800474
      assertions =
        let
          isEnabled = _: v: isAttrs v && (v.enable or false);
          hasDesktopEnabled = cfg: (cfg.enable or false) || !(anyAttrs isEnabled cfg.compositors);
        in
        [
          {
            assertion = (countAttrs isEnabled cfg.compositors) < 2;
            message = "Multiple compositors or window managers cannot be enabled at a time";
          }
          {
            assertion = hasDesktopEnabled cfg;
            message = "Desktop's sub-options cannot be enabled without itself being enabled anyway";
          }
        ];
    }
    (mkIf cfg.enable {
      xdg.portal = {
        enable = cfg.enable;
        xdgOpenUsePortal = mkDefault true;
      };

      environment.systemPackages = attrValues { inherit (pkgs) libnotify xdg-utils; };

      yakumo.user.packages = attrValues {
        inherit (pkgs)
          cliphist # Wayland clipboard manager for both text and images
          slurp # Screen capture tool
          swappy # Screenshot editing tool
          wev # Wayland Key event viewer
          wl-clipboard # Clipboard tool
          wl-screenrec # Screen recorder
          wtype # Keypress simulator
          ;
      };
    })
  ];
}
