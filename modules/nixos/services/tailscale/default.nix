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
      tailCfg = config.services.tailscale;
      # headMeta = config.yakumo.services.metadata.headscale;
    in
    mkMerge [
      {
        services.tailscale = {
          inherit (meta) port; # Default: 41641
          enable = true;
          openFirewall = false; # Default: false
          # Pass extra params to `--auth-key` after the auth key.
          # `tailscale up --auth-key AUTH_KEY_FILE AUTH_KEY_PARAMS... UP_FLAGS...`
          # See: https://tailscale.com/docs/features/oauth-clients#register-new-nodes-using-oauth-credentials
          authKeyParameters = { }; # Default: { }
          authKeyFile = config.sops.secrets."tailscale/auth_key_file".path; # Default: null
          disableTaildrop = !cfg.taildrop.enable; # Default: false
          disableUpstreamLogging = false; # Default: false
          # https://tailscale.com/docs/reference/tailscaled
          extraDaemonFlags = [ ]; # Default: [ ]
          # `tailscale set SET_FLAGS...`
          # https://tailscale.com/docs/reference/tailscale-cli#set
          extraSetFlags = [ ]; # Default: [ ]
          # `tailscale up --auth-key AUTH_KEY_FILE AUTH_KEY_PARAMS... UP_FLAGS...`
          # https://tailscale.com/docs/reference/tailscale-cli#up
          extraUpFlags = [
            # "--login-server"
            # "https://${headMeta.domain}"
          ]; # Default: [ ]
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
          allowedUDPPorts = [ tailCfg.port ];
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
