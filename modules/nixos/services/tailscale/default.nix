# WIP
{
  config,
  lib,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  cfg = config.yakumo.services.tailscale;
  meta = config.yakumo.services.metadata.tailscale;
in
{
  options.yakumo.services.tailscale = {
    enable = mkEnableOption "tailscale";
    taildrop = {
      enable = mkEnableOption "taildrop feature";
    };
  };

  config = mkIf cfg.enable (
    let
      tailscaleCfg = config.services.tailscale;
    in
    mkMerge [
      {
        services.tailscale = {
          inherit (meta) port; # Default: 41641
          enable = true;
          openFirewall = false; # Default: false
          # Pass extra params to `--auth-key` after the auth key.
          # See: https://tailscale.com/docs/features/oauth-clients#register-new-nodes-using-oauth-credentials
          authKeyParameters = { }; # Default: { }
          authKeyFile = config.sops.secrets.tailscale_authkey.path; # Default: null
          disableTaildrop = !cfg.taildrop.enable; # Default: false
          disableUpstreamLogging = false; # Default: false
          extraDaemonFlags = [ ]; # Default: [ ]
          extraSetFlags = [ ]; # Default: [ ]
          extraUpFlags = [ ]; # Default: [ ]
          interfaceName = "tailscale0"; # Default: 'tailscale0'
          # Specify the username or user ID of whom is allowed to fetch
          # Tailscale TLS certificates for the node.
          permitCertUid = null; # Default: null
          # Enable settings required for Tailscale's routing features like
          # subnet routers and exit nodes.
          # If set to 'client' or 'both', reverse path filtering will be set
          # to loose instead of strict.
          # If set to 'server' or 'both', IP forwarding will be enabled.
          useRoutingFeatures = "none"; # Default: 'none' (Options: 'client', 'server', 'both')
        };

        networking.firewall = {
          enable = true;
          trustedInterfaces = [ "tailscale0" ];
          allowedUDPPorts = [ tailscaleCfg.port ];
        };

        # TODO: Consider introducing nftables.
        # See: https://wiki.nixos.org/wiki/Tailscale#Native_nftables_Support_(Modern_Setup)

        sops.secrets = {
          "tailscale/auth_key_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
          };
        };
      }
    ]
  );
}
