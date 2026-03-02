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
      # anki-sync-server = {
      #   enable = true;
      # };
      # calibre = {
      #   enable = true;
      # };
      # forgejo = {
      #   enable = true;
      # };
      # garage = {
      #   enable = true;
      # };
      # grafana = {
      #   enable = true;
      #   stack = [
      #     "loki"
      #     "tempo"
      #   ];
      # };
      # immich = {
      #   enable = true;
      # };
      # influxdb = {
      #   enable = true;
      # };
      # mealie = {
      #   enable = true;
      # };
      # paperless-ngx = {
      #   enable = true;
      # };
      # postgresql = {
      #   enable = true;
      # };
      # rustic = {
      #   enable = true;
      # };
      # samba = {
      #   enable = true;
      # };
      # shiori = {
      #   enable = true;
      # };
      # tailscale = {
      #   enable = true;
      # };
    };
  };
}
