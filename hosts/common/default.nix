{ config, ... }:

{
  yakumo = {
    services = {
      openssh.enable = true;
    };
  };
}
