{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) any hasPrefix mkIf;
  hardwareMods = config.yakumo.hardware.modules;
in
{
  config = mkIf (any (mod: hasPrefix "printer" mod) hardwareMods) {
    # Enable printing support through the CUPS (Common UNIX Printing System) daemon.
    services.printing = {
      enable = true;
      # With this, Systemd will start CUPS on the first incoming connection
      # instead of having it permanently running as a daemon.
      startWhenNeeded = true;
    };
  };
}
