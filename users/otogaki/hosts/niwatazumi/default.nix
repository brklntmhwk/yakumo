{
  config,
  lib,
  ...
}:

{
  imports = [
    ../common # Common configs among user's hosts.
  ];

  yakumo = {
    services = { };
  };
}

