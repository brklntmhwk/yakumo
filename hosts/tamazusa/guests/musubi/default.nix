# WIP.
{
  config,
  ...
}:

{
  imports = [
    ../common
  ];

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
      headscale = {
        enable = true;
      };
    };
  };
}
