{ config, ... }:

{
  yakumo = {
    system = {
      virt = {
        microvm.guest = {
          enable = true;
        };
      };
    };
  };
}
