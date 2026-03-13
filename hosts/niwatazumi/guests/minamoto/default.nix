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
      influxdb = {
        enable = true;
      };
      postgresql = {
        enable = true;
      };
    };
  };
}
