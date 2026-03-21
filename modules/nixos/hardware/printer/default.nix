{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (lib) mkIf;
  inherit (murakumo.utils) anyHasPrefix;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (anyHasPrefix "printer" hardwareMods) {
    # Enable printing support through the CUPS (Common UNIX Printing System) daemon.
    services.printing = {
      enable = true;
      # With this, Systemd will start CUPS on the first incoming connection
      # instead of having it permanently running as a daemon.
      startWhenNeeded = true;
    };
  };
}
