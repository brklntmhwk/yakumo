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
    services = {
      # headscale = {
      #   enable = true;
      # };
      # tailscale = {
      #   enable = true;
      # };
      # stalwart-mail = {
      #   enable = true;
      # };
    };
  };
}
