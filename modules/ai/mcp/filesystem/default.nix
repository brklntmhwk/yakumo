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
    filePaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of file paths to become accessible.";
    };
  };

  config = mkIf cfg.enable (
    let
      inherit (inputs) mcp-servers;
      inherit (lib) optional;
      userCfg = config.yakumo.user;
      xdgCfg = config.yakumo.xdg;
    in
    {
      yakumo.ai.mcp.servers =
        (mcp-servers.lib.evalModule pkgs {
          programs.filesystem = {
            enable = true;
            args =
              optional (cfg.filePaths != [ ]) cfg.filePaths
              ++ optional xdgCfg.enable [
                "${userCfg.home}/Documents"
              ];
          };
        }).config.settings.servers;
    }
  );
}
