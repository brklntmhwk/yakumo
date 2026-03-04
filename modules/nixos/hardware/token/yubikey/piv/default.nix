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
  config = mkIf (elem "token/yubikey/piv" hardwareMods) {
    # Enable PCSC-Lite daemon for accessing smart cards.
    services.pcscd.enable = true;
  };
}
