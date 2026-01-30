{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../common ];

  wsl = {
    enable = true;
    # https://nix-community.github.io/NixOS-WSL/how-to/change-username.html
    defaultUser = config.yakumo.user.name;
  };

  yakumo.system = {
    role = "workstation";
    nix = {
      enableFlake = true;
    };
  };

  # Make this align with the NixOS-WSL version.
  system.stateVersion = "25.05";
}
