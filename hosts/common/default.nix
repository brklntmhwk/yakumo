{ config, ... }:

{
  yakumo = {
    secrets = {
      sops.enable = true;
    };
    services = {
      openssh.enable = true;
    };
  };
}
