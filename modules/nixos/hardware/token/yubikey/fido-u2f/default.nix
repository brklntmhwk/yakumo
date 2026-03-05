{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) elem mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "token/yubikey/fido-u2f" hardwareMods) {
    # https://nixos.wiki/wiki/Yubikey
    security.pam = {
      services = {
        # Enable U2F (Universal 2nd Factor) Authentication for login and sudo.
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
      u2f.settings = {
        # Add --cue to `pam-u2f` so the prompt message appears.
        cue = true;
      };
    };

    # https://nixos.wiki/wiki/Yubikey#Locking_the_screen_when_a_Yubikey_is_unplugged
    # Force the screen to be locked when a Yubikey is unplugged.
    services.udev.extraRules = ''
      ACTION=="remove",\
       ENV{ID_BUS}=="usb",\
       ENV{ID_MODEL_ID}=="0407",\
       ENV{ID_VENDOR_ID}=="1050",\
       ENV{ID_VENDOR}=="Yubico",\
       RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };
}
