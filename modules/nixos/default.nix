{
  murakumo,
  ...
}:

let
  inherit (murakumo.utils) mapModulesRecursively;
in
{
  imports = mapModulesRecursively ./. import;
}
