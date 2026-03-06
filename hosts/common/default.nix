{ config, ... }:

{
  yakumo = {
    services = {
      openssh.enable = true;
    };
    xdg.enable = true;
  };
}
