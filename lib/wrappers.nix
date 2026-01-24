{
  lib,
  makeWrapper,
  symlinkJoin,
}:
let
  inherit (builtins) concatStringsSep;
  inherit (lib)
    escapeShellArg
    escapeShellArgs
    getName
    makeBinPath
    mapAttrsToList
    ;
in
{
  mkAppWrapper =
    {
      pkg,
      name ? null,
      bin ? null,
      flags ? [ ],
      env ? { },
      deps ? [ ],
    }:
    let
      binName =
        if bin != null then
          bin
        else if (pkg.meta ? mainProgram) then
          pkg.meta.mainProgram
        else
          (getName pkg);
      finalName = if name != null then name else "${getName pkg}-wrapped";
      flagsStr = escapeShellArgs flags;
      envStr = concatStringsSep " " (mapAttrsToList (k: v: "--set ${k} ${escapeShellArg v}") env);
      pathStr = if deps == [ ] then "" else "--prefix PATH : ${makeBinPath deps}";
    in
    symlinkJoin {
      name = finalName;
      paths = [ pkg ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        # Verify whether the above-mentioned heuristic works
        if [ ! -x "$out/bin/${binName}" ]; then
          echo "Error: Binary '${binName}' not found in package ${getName pkg}."
          echo "       Available binaries: $(ls $out/bin)"
          exit 1
        fi

        wrapProgram $out/bin/${binName} \
          ${envStr} \
          --add-flags "${flagsStr}" \
          ${pathStr}
      '';
    };
}
