{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.yakumo.ai.mcp.filesystem;
in
{
  options.yakumo.ai.mcp.filesystem = {
    enable = mkEnableOption "Filesystem MCP Server";
    paths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of file or directory paths to become accessible.";
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (inputs) mcp-servers;
      inherit (lib) optionals;
      userCfg = config.yakumo.user;
      xdgCfg = config.yakumo.xdg;
    in
    {
      yakumo.ai.mcp.servers =
        (mcp-servers.lib.evalModule pkgs {
          programs.filesystem = {
            enable = true;
            args =
              cfg.paths
              ++ optionals xdgCfg.enable [
                "${userCfg.home}/Documents"
              ];
          };
        }).config.settings.servers;
    }
  );
}
