# https://github.com/hlissner/dotfiles/commit/a75c64d04ab6c1bc90337d37acb234bde022f9f7
{ lib }:

let
  inherit (builtins)
    concatLists
    elem
    map
    readDir
    pathExists
    ;
  inherit (lib)
    filterAttrs
    hasPrefix
    hasSuffix
    id
    mapAttrs'
    mapAttrsToList
    nameValuePair
    removeSuffix
    ;
in
rec {
  mapFilterModules =
    dir: fn: exclude:
    let
      entries = readDir dir;
      processEntry =
        n: v:
        # Remove those module directories or files specified by the user.
        if elem n exclude then
          nameValuePair "" null
        # e.g., '_foo', '_foo.nix'
        else if hasPrefix "_" n then
          nameValuePair "" null
        # e.g., 'foo/default.nix'
        # Let `dir` be `./.` and `fn` be `import`, then you get:
        # `{ name = "foo"; value = import "./foo"; }`
        else if v == "directory" && pathExists "${dir}/${n}/default.nix" then
          nameValuePair n (fn "${dir}/${n}")
        # e.g., 'foo.nix'
        # The same goes as above.
        else if
          v == "regular"
          && hasSuffix ".nix" n
          && !elem n [
            "default.nix"
            "flake.nix"
          ]
        then
          nameValuePair (removeSuffix ".nix" n) (fn "${dir}/${n}")
        else
          nameValuePair "" null;
    in
    # e.g., `{ foo = import "./foo"; ... }`
    filterAttrs (_: v: v != null) (mapAttrs' processEntry entries);

  mapModules = dir: fn: mapFilterModules dir fn [ ];

  mapFilterModulesRecursively =
    dir: fn: exclude:
    let
      entries = readDir dir;
      dirs = filterAttrs (n: v: v == "directory" && !(elem n exclude) && !(hasPrefix "_" n)) entries;
      files = filterAttrs (
        n: v:
        v == "regular" && hasSuffix ".nix" n && !(elem n exclude) && n != "flake.nix" && !(hasPrefix "_" n)
      ) entries;
      paths =
        (mapAttrsToList (n: _: "${dir}/${n}") files)
        ++ concatLists (mapAttrsToList (n: _: mapFilterModulesRecursively "${dir}/${n}" id exclude) dirs);
    in
    map fn paths;

  mapModulesRecursively = dir: fn: mapFilterModulesRecursively dir fn [ ];
}
