{ lib, runCommand }:

let
  inherit (builtins)
    attrNames
    attrValues
    concatLists
    concatMap
    concatStringsSep
    head
    readDir
    toString
    tail
    ;
  inherit (lib)
    all
    any
    filterAttrs
    findFirst
    id
    isAttrs
    isDerivation
    isList
    isPath
    last
    length
    mapAttrsToList
    pipe
    zipAttrsWith
    ;
in
rec {
  # https://github.com/hlissner/dotfiles/commit/a75c64d04ab6c1bc90337d37acb234bde022f9f7
  anyAttrs = pred: attrs: any (attr: pred attr.name attr.value) (attrsToList attrs);

  # https://github.com/hlissner/dotfiles/commit/a75c64d04ab6c1bc90337d37acb234bde022f9f7
  countAttrs = pred: attrs: count (attr: pred attr.name attr.value) (attrsToList attrs);

  anyEnabled = attrs: any (subModule: subModule.enable or false) (attrValues attrs);

  getDirNames =
    dir:
    pipe (readDir dir) [
      (filterAttrs (name: v: v == "directory"))
      attrNames
    ];

  getDirNamesRecursive =
    dir:
    let
      children = getDirNames dir;
    in
    concatMap (
      name:
      let
        # Recurse this function itself.
        subChildren = getDirNamesRecursive (dir + "/${name}");
        # Prepend the current name to the sub-children to build the path string
        # e.g., "gpu" + "nvidia" --> "gpu/nvidia"
        prefixedSubChildren = map (child: "${name}/${child}") subChildren;
      in
      [ name ] ++ prefixedSubChildren
    ) children;

  findFirstAttrName =
    pred: attrs:
    let
      keys = attrNames attrs;
      finder = k: pred k attrs.${k};
    in
    findFirst finder null keys;

  getNixfileNames =
    dir:
    pipe (readDir dir) [
      (filterAttrs (name: v: v == "regular" && hasSuffix ".nix" name))
      attrNames
      (map (removeSuffix ".nix"))
    ];

  # https://github.com/hlissner/dotfiles/commit/482be0f29ad6930198f8f2e825bcd5baa6c18c2c
  mergeAttrs' =
    attrList:
    zipAttrsWith (
      name: values:
      if length values == 1 then
        head values
      else if all isList values then
        concatLists values
      else if all isAttrs values then
        mergeAttrs' values
      else
        last values
    ) attrList;

  mapModules =
    dir: fn:
    let
      entries = readDir dir;
      processEntry =
        n: v:
        if hasPrefix "_" n then
          null
        else if v == "directory" && pathExists "${dir}/${n}/default.nix" then
          nameValuePair n (fn "${dir}/${n}")
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
          null;
    in
    filterAttrs (_: v: v != null) (mapAttrs' processEntry entries);

  # https://github.com/hlissner/dotfiles/commit/a75c64d04ab6c1bc90337d37acb234bde022f9f7
  mapModulesRec' =
    dir: fn:
    let
      dirs = mapAttrsToList (k: _: "${dir}/${k}") (
        filterAttrs (n: v: v == "directory" && !(hasPrefix "_" n) && !(pathExists "${dir}/${n}/.noload")) (
          readDir dir
        )
      );
      files = attrValues (mapModules dir id);
      paths = files ++ concatLists (map (d: mapModulesRec' d id) dirs);
    in
    map fn paths;
}
