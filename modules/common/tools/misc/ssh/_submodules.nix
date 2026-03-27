{ lib }:

let
  inherit (lib)
    mkOption
    types
    ;
in
{
  allowedSigners =
    { ... }:
    {
      options = {
        email = mkOption {
          type = types.str;
          description = "Email addresss for the signer.";
        };
        key = mkOption {
          type = types.str;
          description = "SSH public key for the signer.";
        };
      };
    };
}
