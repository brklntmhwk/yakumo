{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.yakumo.programs.cli-utils;
in
{
  options.yakumo.programs.cli-utils = {
    enable = mkEnableOption "CLI utilities";
  };

  config = mkIf cfg.enable {
    yakumo.user.packages = builtins.AttrValues {
      # Install util CLIs altogether that you don't need to wrap with their configurations.
      inherit (pkgs)
        bat # Quick file content check util - a prettified 'cat' alternative
        curlie # 'curl' with the ease of use
        dasel # Versatile data selector, converter, and modification util
        duf # Disk usage/free util - a better 'df' alternative
        dust # Disk usage check util - a more intuitive 'du' alternative
        eza # A prettified modern ver. of 'ls'
        fastfetch # System info tool
        fd # File/folder search util - a faster & more user-friendly 'find' altenative
        hyperfine # Benchmarking CLI tool
        navi # Interactive cheatsheet CLI tool
        ouch # Painless compression & decompression in the terminal
        pastel # Color analysis, convertion, and manipulation CLI tool
        pipr # Interactive shell pipeline writing CLI tool
        procs # Process viewer - an improved modern 'ps' alternative
        ripgrep # Recursive & regex pettern matching search util
        sd # Find & replace CLI tool - a more intuitive 'sed' alternative
        tealdeer # Faster and modern implementation of `tldr` - a community-maintained simpler version of the `man` cheatsheets for commands
        tokei # Code counting & statistics CLI tool
        tre-command # Directory tree viewer in the terminal - an improved 'tree' alternative
        ;
    };
  };
}
