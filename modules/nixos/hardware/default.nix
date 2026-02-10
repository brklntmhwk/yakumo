{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib) mkDefault mkOption types;
  inherit (murakumo.utils) getDirNamesRecursive;
  hardwareMods = getDirNamesRecursive ./.;
in {
  options.yakumo.hardware = {
    # 'yakumo.hardware.*' modules look up this.
    modules = mkOption {
      type = types.listOf (types.enum hardwareMods);
      default = [ ];
      description = "List of hardware modules to enable.";
    };
  };

  config = {
    # Enable unfree (proprietary) firmware support. (especially Wi-Fi cards and GPUs)
    # This line is written in "/nix/store/.../modules/installer/scan/not-detected.nix".
    # 'hardware-configuration.nix' usually imports this like:
    # `imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];`
    # So this is a result of dismantling 'hardware-configuration.nix'.
    hardware.enableRedistributableFirmware = mkDefault true;
  };
}
