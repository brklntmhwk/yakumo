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
      home-assistant = {
        enable = true;
      };
      mosquitto = {
        enable = true;
      };
      owntracks = {
        enable = true;
        mqttIntegration = {
          enable = true;
        };
        frontend = {
          enable = true;
        };
      };
    };
  };
}
