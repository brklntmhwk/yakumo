{ config, ... }:

{
  yakumo.secrets = {
    sops = {
      enable = true;
    };
  };

  yakumo.services = {
    openssh = {
      enable = true;
    };
  };
}
