{ config, ... }:

{
  yakumo = {
    system = {
      # persistence.yosuga = {
      #   enable = true;
      # };
    };
    services = {
      openssh.enable = true;
    };
    xdg.enable = true;
  };
}
