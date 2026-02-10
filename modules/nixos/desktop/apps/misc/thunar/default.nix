{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
  cfg = config.yakumo.desktop.apps.misc.thunar;
in {
  options.yakumo.desktop.apps.misc.thunar = {
    enable = mkEnableOption "thunar";
    # https://github.com/NixOS/nixpkgs/commit/bb5ec4625ac3237631c7a0957c78cc79735fd2ad
    plugins = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        List of thunar plugins to install.
      '';
    };
    package = mkPackageOption pkgs.xfce "thunar" { };
  };

  config = mkIf cfg.enable (let
    overriddenThunarPkg = cfg.package.override { thunarPlugins = cfg.plugins; };
  in {
    yakumo.user.packages = [ overriddenThunarPkg ];
    services.dbus.packages = [ overriddenThunarPkg ];
    systemd.packages = [ overriddenThunarPkg ];
    programs.xfconf.enable = true;
  });
}
