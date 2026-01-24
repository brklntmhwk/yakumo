{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (murakumo.utils) mapModulesRec';
in
{
  imports = mapModulesRec' ./modules import;
}
