{ lib, runCommand }:

let
  inherit (builtins)
    attrNames
    attrValues
    concatLists
    concatMap
    head
    map
    readDir
    ;
  inherit (lib)
    all
    any
    attrsToList
    count
    filterAttrs
    findFirst
    hasSuffix
    isAttrs
    isList
    last
    length
    nameValuePair
    pipe
    removeSuffix
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
}
