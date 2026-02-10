{ config, lib, pkgs, murakumo, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types;
  cfg = config.yakumo.desktop.lockers.swaylock;
in {
  options.yakumo.desktop.lockers.swaylock = {
    enable = mkEnableOption "swaylock";
    # https://github.com/nix-community/home-manager/commit/2df3d5d39c5ef3a4eebe80d478d75c9e20d5c820
    settings = mkOption {
      type = types.attrsOf
        (types.oneOf [ types.bool types.float types.int types.path types.str ]);
      default = { };
      description = ''
        Swaylock configuraion in Nix-representable format.
        For the valid setting options, see:
        https://man.archlinux.org/man/swaylock.1
      '';
      example = {
        color = "808080";
        font-size = 24;
        indicator-idle-visible = false;
        indicator-radius = 100;
        line-color = "ffffff";
        show-failed-attempts = true;
      };
    };
    package = mkPackageOption pkgs "swaylock" { };
    packageWrapped = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The final wrapped Swaylock package, including all configurations.
        Use this if you need to reference it in other modules.
      '';
    };
  };

  config = mkIf cfg.enable (let
    inherit (builtins) isPath isString toString;
    inherit (lib) concatStrings getName hasPrefix mapAttrsToList removePrefix;
    inherit (pkgs) writeText;
    inherit (murakumo.wrappers) mkAppWrapper;

    formatValue = val:
      if isPath val then
        "${val}"
      else if (isString val) && (hasPrefix "#" val) then
        removePrefix "#" val
      else
        toString val;
    swaylockConf = writeText "config" (concatStrings (mapAttrsToList (name: val:
      if val == false then
        ""
      else
        (if val == true then name else name + "=" + (formatValue val)) + "\n")
      cfg.settings));
    swaylockWrapped = mkAppWrapper {
      pkg = cfg.package;
      name = "${getName cfg.package}-${config.yakumo.user.name}";
      flags = [ "--config" swaylockConf ];
    };
  in {
    yakumo.desktop.lockers.swaylock.packageWrapped = swaylockWrapped;
    environment.systemPackages = [ swaylockWrapped ];

    # Enable PAM access for authentication.
    security.pam.services.swaylock = { };
  });
}
