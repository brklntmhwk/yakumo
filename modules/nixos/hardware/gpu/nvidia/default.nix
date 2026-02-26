{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) elem mkDefault mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "gpu/nvidia" hardwareMods) {
    services.xserver.videoDrivers = mkDefault [ "nvidia" ];
    hardware.graphics = {
      # Enabling desktop automatically turns this on.
      # enable = true;
      enable32Bit = true;
      extraPackages = [ ];
    };
    hardware.nvidia = {
      modesetting.enable = true; # Most Wayland compositors need this.
      powerManagement.enable = true;
      nvidiaSettings = true;
      open = mkDefault false; # Use proprietary drivers.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
