# WIP
{
  config,
  lib,
  murakumo,
  rootMeta,
  rootPath,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.yakumo.services.tailscale;
  meta = config.yakumo.services.metadata.tailscale;
  routingRoles = [
    "none"
    "client"
    "server"
    "both"
  ];
in
{
  options.yakumo.services.tailscale = {
    enable = mkEnableOption "tailscale";
    taildrop = {
      enable = mkEnableOption "taildrop feature";
    };
    routingRole = mkOption {
      type = types.enum routingRoles;
      default = "none";
      description = ''
        Choice of the routing roles required for Tailscale's routing features, such as
        subnet routers and exit nodes.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (config.services.tailscale) interfaceName port;
      headMeta = config.yakumo.services.metadata.headscale;
    in
    mkMerge [
      {
        assertions =
          let
            inherit (murakumo.assertions) assertServiceUp;
          in
          [
            (assertServiceUp "tailscale" rootMeta.allServices)
            {
              assertion = cfg.enable -> (rootMeta.service.vpn == "headscale");
              message = ''
                Headscale must be specified globally as the VPN solution if using Tailscale
              '';
            }
          ];

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
            # Bypass the official Tailscale control plane and talk directly to your server.
            "--login-server=https://${headMeta.domain}"
          ]; # Default: [ ]
          interfaceName = "tailscale0"; # Default: 'tailscale0'
          # Specify the username or user ID of whom is allowed to fetch
          # Tailscale TLS certificates for the node.
          # As we use the self-hosted Headscale server, leave this `null` and let
          # the Headscale server itself have a valid TLS certificate, not the
          # individual Tailscale clients.
          permitCertUid = null; # Default: null
          # Enable settings required for Tailscale's routing features like
          # subnet routers and exit nodes.
          # Options:
          # - 'client': Allows asymmetrical routing so our web traffic can securely
          # exit from another node.
          # - 'server': Automatically enables IP forwarding in the kernel.
          # - 'both': Does of them.
          # - 'none': Does nothing.
          # If set to 'client' or 'both', reverse path filtering will be set
          # to 'loose' instead of 'strict'.
          # If set to 'server' or 'both', IP forwarding will be enabled
          # (i.e., `boot.kernel.sysctl."net.{ipv4|ipv6}.conf.all.forwarding" = true`).
          useRoutingFeatures = cfg.routingRole; # Default: 'none'
        };

        # https://wiki.nixos.org/wiki/Tailscale#Native_nftables_Support_(Modern_Setup)
        networking = {
          # The modern solution to packet filtering as of 2026.
          nftables = {
            enable = true;
          };
          firewall = {
            enable = true;
            trustedInterfaces = [ interfaceName ];
            allowedUDPPorts = [ port ];
            # Perform a reverse path filter test on a packet.
            # Options: 'strict', 'loose', or bool
            # - 'strict' (or `true`): Drops the packet if it's asymmetrical: A response
            # to the packet isn't sent via the same interface as the one the packet
            # arrives on.
            # - 'loose': Only drops the packet if the source address is not reachable
            # via any interfaces.
            # - `false`: Disables it.
            # Set it to "loose" to prevent the firewall from aggressively dropping
            # asymmetrical VPN routing. This is required to use Tailscale Exit Nodes.
            # Also, setting `services.tailscale.useRoutingFeatures` to either 'client'
            # or 'both' automatically sets this to 'loose'.
            # checkReversePath = "loose"; # Default: true
          };
        };

        # https://wiki.nixos.org/wiki/Tailscale#Native_nftables_Support_(Modern_Setup)
        systemd.services.tailscaled.serviceConfig.Environment = [
          # As the Tailscale's default firewall mode is iptables, manually set it
          # to nftables if you want.
          # https://tailscale.com/docs/features/firewall-mode
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];

        yakumo =
          let
            yosugaCfg = config.yakumo.system.persistence.yosuga;
          in
          mkMerge [
            (mkIf yosugaCfg.enable {
              system.persistence.yosuga = {
                directories = [
                  {
                    path = "/var/lib/tailscale";
                    mode = "0700";
                  }
                  {
                    path = "/var/cache/tailscale";
                    mode = "0750";
                  }
                ];
              };
            })
          ];

        sops.secrets = {
          "tailscale/auth_key_file" = {
            sopsFile = rootPath + "/secrets/default.yaml";
          };
        };
      }
    ]
  );
}
