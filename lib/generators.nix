{ lib }:
let
  inherit (builtins) elem map removeAttrs replaceStrings toString typeOf;
  inherit (lib)
    all any concatMapStringsSep concatStrings concatStringsSep filterAttrs
    flatten foldl generators hasPrefix isAttrs isBool isList optional
    optionalString pipe replicate splitString throwIfNot mapAttrsToList;
in {
  generators = {
    # https://github.com/nix-community/home-manager/commit/9fdd301a5e4d8cf4d4cf3f990e799000a54a3737
    toHyprconf = { attrs, indentLevel ? 0, importantPrefixes ? [ "$" ], }:
      let
        initialIndent = concatStrings (replicate indentLevel "  ");

        toHyprconf' = indent: attrs:
          let
            sections =
              filterAttrs (n: v: isAttrs v || (isList v && all isAttrs v))
              attrs;

            mkSection = n: attrs:
              if isList attrs then
                (concatMapStringsSep "\n" (a: mkSection n a) attrs)
              else ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              '';

            mkFields = generators.toKeyValue {
              listsAsDuplicateKeys = true;
              inherit indent;
            };

            allFields =
              filterAttrs (n: v: !(isAttrs v || (isList v && all isAttrs v)))
              attrs;

            isImportantField = n: _:
              foldl (acc: prev: if hasPrefix prev n then true else acc) false
              importantPrefixes;

            importantFields = filterAttrs isImportantField allFields;

            fields =
              removeAttrs allFields (mapAttrsToList (n: _: n) importantFields);
          in mkFields importantFields
          + concatStringsSep "\n" (mapAttrsToList mkSection sections)
          + mkFields fields;
      in toHyprconf' initialIndent attrs;

    # https://github.com/nix-community/home-manager/commit/dc5899978f8fa5d72424d5242784fb7e84e8573e
    toMakoConf = { attrs, }:
      let
        formatValue = v:
          if isBool v then if v then "true" else "false" else toString v;

        globalSettings = filterAttrs (n: v: !(isAttrs v)) attrs;
        sectionSettings = filterAttrs (n: v: isAttrs v) attrs;

        globalLines = concatStringsSep "\n"
          (mapAttrsToList (k: v: "${k}=${formatValue v}") globalSettings);

        formatSection = name: content:
          ''

            [${name}]
          '' + concatStringsSep "\n"
          (mapAttrsToList (k: v: "${k}=${formatValue v}") content);

        sectionLines =
          concatStringsSep "\n" (mapAttrsToList formatSection sectionSettings);
      in concatStringsSep "\n" (globalLines ++ sectionLines);

    toSwayidleConf = { attrs, }:
      let
        timeoutStr = t:
          "timeout ${toString t.timeout} '${t.command}'"
          + (optionalString (t.resumeCommand != null)
            " resume '${t.resumeCommand}'");
        eventStr = e: "${e.event} '${e.command}'";

        timeouts = map timeoutStr (attrs.timeouts or [ ]);
        events = map eventStr (attrs.events or [ ]);
      in concatStringsSep "\n" (timeouts ++ events);

    # https://github.com/nix-community/home-manager/commit/fce9dbfeb4fa0b0878cf4ebd375d4f2b5acc87b0
    toKDL = { }:
      let
        # ListOf String -> String
        indentStrings = let
          # Although the input of this function is a list of strings,
          # the strings themselves *will* contain newlines, so you need
          # to normalize the list by joining and resplitting them.
          unlines = splitString "\n";
          lines = concatStringsSep "\n";
          indentAll = lines: concatStringsSep "\n" (map (x: "	" + x) lines);
        in stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

        # String -> String
        sanitizeString = replaceStrings [ "\n" ''"'' ] [ "\\n" ''\"'' ];

        # OneOf [Int Float String Bool Null] -> String
        literalValueToString = element:
          throwIfNot
          (elem (typeOf element) [ "int" "float" "string" "bool" "null" ])
          "Cannot convert value of type ${typeOf element} to KDL literal."
          (if typeOf element == "null" then
            "null"
          else if element == false then
            "false"
          else if element == true then
            "true"
          else if typeOf element == "string" then
            ''"${sanitizeString element}"''
          else
            toString element);

        # Attrset Conversion
        # String -> AttrsOf Anything -> String
        convertAttrsToKDL = name: attrs:
          let
            optArgs = map literalValueToString (attrs._args or [ ]);
            optProps = mapAttrsToList
              (name: value: "${name}=${literalValueToString value}")
              (attrs._props or { });

            orderedChildren = pipe (attrs._children or [ ]) [
              (map (child: mapAttrsToList convertAttributeToKDL child))
              flatten
            ];
            unorderedChildren = pipe attrs [
              (filterAttrs
                (name: _: !(elem name [ "_args" "_props" "_children" ])))
              (mapAttrsToList convertAttributeToKDL)
            ];
            children = orderedChildren ++ unorderedChildren;
            optChildren = optional (children != [ ]) ''
              {
              ${indentStrings children}
              }'';
          in concatStringsSep " "
          ([ name ] ++ optArgs ++ optProps ++ optChildren);

        # List Conversion
        # String -> ListOf (OneOf [Int Float String Bool Null])  -> String
        convertListOfFlatAttrsToKDL = name: list:
          let flatElements = map literalValueToString list;
          in "${name} ${concatStringsSep " " flatElements}";

        # String -> ListOf Anything -> String
        convertListOfNonFlatAttrsToKDL = name: list: ''
          ${name} {
          ${indentStrings (map (x: convertAttributeToKDL "-" x) list)}
          }'';

        # String -> ListOf Anything  -> String
        convertListToKDL = name: list:
          let
            elementsAreFlat = !any (el: elem (typeOf el) [ "list" "set" ]) list;
          in if elementsAreFlat then
            convertListOfFlatAttrsToKDL name list
          else
            convertListOfNonFlatAttrsToKDL name list;

        # Combined Conversion
        # String -> Anything  -> String
        convertAttributeToKDL = name: value:
          let vType = typeOf value;
          in if elem vType [ "int" "float" "bool" "null" "string" ] then
            "${name} ${literalValueToString value}"
          else if vType == "set" then
            convertAttrsToKDL name value
          else if vType == "list" then
            convertListToKDL name value
          else
            throw ''
              Cannot convert type `(${typeOf value})` to KDL:
                ${name} = ${toString value}
            '';
      in attrs: ''
        ${concatStringsSep "\n" (mapAttrsToList convertAttributeToKDL attrs)}
      '';
  };

  mkRonLiteral = value: {
    _type = "ron-literal";
    inherit value;
  };

  toRon = { attrs, indentLevel ? 0, }:
    let
      indent = n: concatStrings (replicate n "  ");
      toRon' = lvl: v:
        let type = typeOf v;
        in if type == "set" && v ? _type && v._type == "ron-literal" then
          v.value
        else if type == "set" then
          let
            fields = mapAttrsToList
              (k: val: "${indent (lvl + 1)}${k}: ${toRon' (lvl + 1) val},") v;
          in ''
            (
            ${concatStringsSep "\n" fields}
            ${indent lvl})''
        else if type == "list" then
          let vals = map (x: "${indent (lvl + 1)}${toRon' (lvl + 1) x},") v;
          in ''
            [
            ${concatStringsSep "\n" vals}
            ${indent lvl}]''
        else if type == "string" then
          ''"${replaceStrings [ ''"'' ] [ ''\"'' ] v}"''
        else if type == "bool" then
          (if v then "true" else "false")
        else if type == "null" then
          "None"
        else
          toString v;
    in toRon' indentLevel attrs;
}
