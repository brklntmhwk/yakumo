{
  config,
  pkgs,
  lib,
  murakumo,
  ...
}:

let
  inherit (builtins) attrValues;
  inherit (lib)
    elem
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (murakumo.platforms) isLinux;
  cfg = config.yakumo.system.security.yubikey;
  supportedProtocols = [
    "fido-u2f" # FIDO-U2F
    "piv" # Peasonal Identity Verification
  ];
in
{
  options.yakumo.system.security.yubikey = {
    enable = mkEnableOption "Yubikey integrations";
    protocols = mkOption {
      type = types.listOf (types.enum supportedProtocols);
      default = [ ];
      description = "List of authentication protocols to be used.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = attrValues {
        inherit (pkgs)
          yubikey-manager # The modern CLI tool (ykman)
          yubikey-personalization # The legacy tools
          ;
      };

      # Lets you know when Yubikey's waiting for skinship.
      programs.yubikey-touch-detector = {
        enable = true;
        libnotify = true; # Default: true
        unixSocket = true; # Default: true
      };
    }
    (mkIf isLinux {
      services.udev.packages = attrValues { inherit (pkgs) yubikey-personalization; };

      # Enable PCSC-Lite daemon for accessing smart cards.
      services.pcscd.enable = mkIf (elem "piv" cfg.protocols) true;

      # https://nixos.wiki/wiki/Yubikey
      security.pam.services = mkIf (elem "fido-u2f" cfg.protocols) {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
    })
  ]);
}
