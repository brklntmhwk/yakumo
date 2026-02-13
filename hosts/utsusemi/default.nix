{ inputs, config, lib, ... }:

{
  imports = [ ../common ];

  wsl = {
    enable = true;
    # https://nix-community.github.io/NixOS-WSL/how-to/change-username.html
    defaultUser = config.yakumo.user.name;
  };

  yakumo.system = {
    role = "workstation";
    nix = { enableFlake = true; };
    # persistence.yosuga = {
    #   enable = true;
    #   directories = [
    #     "/etc/nixos"
    #   ];
    #   files = [
    #     "/etc/machine-id"
    #     "/etc/ssh/ssh_host_ed25519_key"
    #     "/etc/ssh/ssh_host_ed25519_key.pub"
    #     "/etc/ssh/ssh_host_rsa_key"
    #     "/etc/ssh/ssh_host_rsa_key.pub"
    #   ];
    # };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      # Run `locale` to see available options
    };
    extraLocales = [
      "en_US.UTF-8/UTF-8"
      "en_GB.UTF-8/UTF-8"
      "es_ES.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
  };

  # Make this align with the NixOS-WSL version.
  system.stateVersion = "25.05";
}
