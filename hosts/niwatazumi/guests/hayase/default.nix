# WIP.
{
  config,
  ...
}:

{
  yakumo = {
    system = {
      virt = {
        microvm.guest = {
          macAddress = "02:00:00:00:00:02";
          memorySize = 512;
        };
      };
    };
    services = {
      anki-sync-server = {
        enable = true;
      };
      calibre-web = {
        enable = true;
      };
      forgejo = {
        enable = true;
      };
      mealie = {
        enable = true;
      };
      paperless-ngx = {
        enable = true;
      };
      shiori = {
        enable = true;
      };
    };
  };
}
