{
  murakumo,
  ...
}:

let
  inherit (murakumo.modules) mapModulesRecursively;
in
{
  imports = mapModulesRecursively ./. import;
}
