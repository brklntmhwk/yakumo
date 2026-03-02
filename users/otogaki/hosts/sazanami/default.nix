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
      # adguardhome = {
      #   enable = true;
      # };
      # home-assistant = {
      #   enable = true;
      # };
      # kanidm = {
      #   enable = true;
      # };
      # mosquitto = {
      #   enable = true;
      # };
      # owntracks = {
      #   enable = true;
      # };
      # tailscale = {
      #   enable = true;
      # };
      # vaultwarden = {
      #   enable = true;
      # };
    };
  };
}
