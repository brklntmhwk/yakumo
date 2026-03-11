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
      kanidm = {
        enable = true;
      };
      vaultwarden = {
        enable = true;
      };
    };
  };
}
