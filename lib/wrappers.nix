# Based on:
# https://github.com/viperML/wrapper-manager/commit/7a983c3d3b041f6a85dbe0252db9ad677be287b5
{
  lib,
  makeWrapper,
  symlinkJoin,
  xorg,
}:
let
  inherit (builtins) any concatStringsSep hasAttr;
  inherit (lib)
    concatMapStringsSep
    escapeShellArg
    escapeShellArgs
    flatten
    getExe
    getName
    makeBinPath
    mapAttrsToList
    optional
    optionals
    optionalString
    ;
in
{
  mkWrapper =
    {
      pkg,
      name ? null,
      bin ? null,
      prependFlags ? [ ],
      appendFlags ? [ ],
      setEnv ? { },
      preCommands ? [ ],
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
      # This check is necessary to avoid the "attribute 'man' missing" error.
      # As `symlinkJoin` only produces a single default output (`out`), it crashes
      # when Nix tries to access `.man` on it.
      # Will be used later for the `outputs` and `meta` attributes.
      hasMan = any (hasAttr "man") ([ pkg ] ++ deps);
    in
    symlinkJoin {
      name = finalName;
      paths = [ pkg ] ++ deps;
      buildInputs = [ makeWrapper ];
      passthru = (pkg.passthru or { }) // {
        unwrapped = pkg;
      };
      outputs = [ "out" ] ++ (optional hasMan "man");
      postBuild =
        let
          args =
            optionals (setEnv != { }) (
              flatten (
                mapAttrsToList (k: v: [
                  "--set"
                  k
                  v
                ]) setEnv
              )
            )
            ++ optionals (preCommands != [ ]) (
              flatten (
                map (x: [
                  "--run"
                  x
                ]) preCommands
              )
            )
            ++ optionals (prependFlags != [ ]) [
              "--add-flags"
              (escapeShellArgs prependFlags)
            ]
            ++ optionals (appendFlags != [ ]) [
              "--append-flags"
              (escapeShellArgs appendFlags)
            ];
        in
        ''
          # Verify whether the above-mentioned heuristic works.
          if [ ! -x "$out/bin/${binName}" ]; then
            echo "Error: Binary '${binName}' not found in package ${getName pkg}."
            echo "       Available binaries: $(ls $out/bin)"
            exit 1
          fi

          wrapProgram $out/bin/${binName} \
            ${escapeShellArgs args}

          ${optionalString hasMan ''
            mkdir -p ''${!outputMan}
            ${concatMapStringsSep "\n" (
              p:
              if p ? "man" then
                "${getExe xorg.lndir} -silent ${p.man} \${!outputMan}"
              else
                ''echo "No man output for ${getName p}"''
            ) ([ pkg ] ++ deps)}
          ''}
        '';
      meta = (pkg.meta or { }) // {
        outputsToInstall = [ "out" ] ++ (optional hasMan "man");
      };
    };
}
