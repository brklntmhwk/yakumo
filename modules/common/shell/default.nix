{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  cfg = config.yakumo.shell;
in
{
  config =
    let
      inherit (murakumo.utils) anyAttrs countAttrs;

      isDefaultShell = _: v: v.defaultShell or false;
    in
    {
      assertions = [
        {
          assertion = anyAttrs isDefaultShell cfg;
          message = "Default shell must be specified";
        }
        {
          assertion = (countAttrs isDefaultShell cfg) < 2;
          message = "Multiple shells cannot be set as default at a time";
        }
      ];
    };
}
