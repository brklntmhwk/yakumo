{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.system.networking.networkmanager;
  systemRole = config.yakumo.system.role;
in
{

}
