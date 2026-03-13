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
      garage = {
        enable = true;
      };
      immich = {
        enable = true;
      };
      samba = {
        enable = true;
      };
    };
  };
}
