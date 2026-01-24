{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Host-specific configurations.
    ./configs/i18n
  ];

  yakumo.system = {
    role = "workstation";
    nix = {
      enableFlake = true;
    };
    network = {
      manager = "networkd";
    };
  };

  yakumo.secrets = {
    sops = {
      enable = true;
    };
  };

  yakumo.hardware = {
    modules = [
      "audio"
      "bluetooth/blueman"
      "gpu/nvidia"
      "monitor"
      "printer/bambu-lab"
      "scanner/scansnap"
    ];
  };

  yakumo.services = {
    openssh = {
      enable = true;
    };
  };

  nix = {
    # Garbage Collection related settings.
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    package = pkgs.lix;
    settings = {
      # Have Nix optimise the Nix store to free up more space in disk
      auto-optimise-store = true;
      # Make it so any users in the wheel user group trusted.
      trusted-users = [ "@wheel" ];
      # No warning emitted when git is not pushed.
      warn-dirty = false;
      # Force XDG Base Directory convention.
      # use-xdg-base-directories = true;
    };
  };

  # Don't modify this unless you're sure about the effects.
  system.stateVersion = "24.11";
}
