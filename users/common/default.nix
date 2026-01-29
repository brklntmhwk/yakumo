{ pkgs, ... }:

{
  time.timeZone = "Asia/Tokyo";

  environment.systemPackages = (
    let
      inherit (pkgs) hunspellDicts;
    in
    attrValues {
      # Dictionaries for multiple languages
      inherit (hunspellDicts)
        en-us
        en-gb-ise
        es-any
        ;
      inherit (pkgs)
        ;
    }
  );
}
