{ stdenv }:

{
  inherit (stdenv) isDarwin isLinux;
  inherit (stdenv.hostPlatform) isAarch64 isx86_64;
}
