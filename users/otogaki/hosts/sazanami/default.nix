{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (theme) fonts;
in
{
  imports = [
    ../common # Common configs among user's hosts.
  ];

  yakumo = {
    services = { };
  };
}
