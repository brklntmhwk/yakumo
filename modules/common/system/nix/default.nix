{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    mkMerge
    mkPackageOption
    ;
  cfg = config.yakumo.system.nix;
  systemRole = config.yakumo.system.role;
in
{
  options.yakumo.system.nix = {
    enableFlake = mkEnableOption "Nix Flakes";
    package = mkPackageOption pkgs "nix" { };
  };

  config = mkMerge [
    {
      nix.package = cfg.package;
    }
    (mkIf cfg.enableFlake {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    })
    (mkIf (systemRole == "workstation") {
      nix = {
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
          # Ensure GC runs on boot if missed.
          persistent = true;
        };
        settings = {
          trusted-users = [
            "root"
            "@wheel"
          ];
          auto-optimise-store = true;
        };
      };
    })
    (mkIf (systemRole == "server") {
      nix = {
        gc = {
          # Results in mountains of garbage otherwise.
          automatic = mkForce true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };
        settings = {
          trusted-users = [
            "root"
          ];
          # If set to true, this "Auto" optimisation runs on every file write.
          # On a server performing updates or builds, this could add significant
          # CPU/IO overhead.
          auto-optimise-store = mkForce false;
          # The maximum number of jobs Nix tries to build in parallel.
          # max-jobs = "2"; # Default: "auto"
        };
        optimise = {
          automatic = mkForce true;
          dates = [
            "03:30" # In the dead of night...
          ];
        };
      };
    })
  ];
}
