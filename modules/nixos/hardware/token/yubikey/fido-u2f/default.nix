{
  config,
  lib,
  ...
}:

let
  inherit (lib) elem mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (elem "token/yubikey/fido-u2f" hardwareMods) {
    # https://nixos.wiki/wiki/Yubikey
    security.pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
  };
}
