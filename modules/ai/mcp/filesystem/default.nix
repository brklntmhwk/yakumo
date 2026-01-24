{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.yakumo.ai.mcp.filesystem;
in
{
  options.yakumo.ai.mcp.filesystem = {
    enable = mkEnableOption "Filesystem MCP Server";
  };

  config = mkIf cfg.enable (
    let
      inherit (inputs) mcp-servers;
    in
    {
      yakumo.ai.mcp.servers =
        (mcp-servers.lib.evalModule pkgs {
          programs.filesystem = {
            enable = true;
            # TODO: add a directory path.
            # args = [];
          };
        }).config.settings.servers;
    }
  );
}
