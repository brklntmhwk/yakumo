{
  config,
  lib,
  pkgs,
  murakumo,
  ...
}:

let
  inherit (builtins) isAttrs;
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
  inherit (murakumo.utils) anyAttrs countAttrs;

  cfg = config.yakumo.ai.mcp;
in
{
  options.yakumo.ai.mcp = {
    enable = mkEnableOption "MCP servers";
    servers = mkOption {
      type = types.attrsOf (
        types.submodule {
          # https://geminicli.com/docs/tools/mcp-server/#configuration-properties
          # https://github.com/natsukium/mcp-servers-nix/commit/2f242905643b0b1145def24d66cd1b98ef5bf71f
          options = {
            command = mkOption {
              type = types.str;
            };
            args = mkOption {
              type = types.listOf (
                types.oneOf [
                  types.bool
                  types.int
                  types.str
                ]
              );
              default = [ ];
            };
            env = mkOption {
              type = types.attrsOf (
                types.oneOf [
                  types.bool
                  types.int
                  types.str
                ]
              );
              default = { };
            };
            url = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        }
      );
      readOnly = true;
      description = ''
        The merged mcpServers configuration of all enabled MCP servers in Nix-representable JSON format.
      '';
    };
  };

  config = {
    assertions =
      let
        isEnabled = _: v: v.enable or false;
        hasMcpServersEnabled =
          cfg: (anyAttrs isEnabled cfg) || !(anyAttrs (_: v: isAttrs v && anyAttrs isEnabled v) cfg);
      in
      [
        {
          assertion = hasMcpServersEnabled cfg;
          message = "MCP servers' sub-options cannot be enabled without itself being enabled anyway.";
        }
      ];
  };
}
