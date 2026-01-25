{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (murakumo.utils) mapModulesRecursively;
in
  # TODO: any more configs that should be here?
{
  imports = mapModulesRecursively ./modules import;
}
