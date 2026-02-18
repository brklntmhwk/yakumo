# Based on:
# https://github.com/viperML/dotfiles/commit/62a757938bee8a0c44f5a7c0c5c2fef24e345c63
{ lib }:

let
  inherit (lib) composeManyExtensions;

  overlayPkgs = final: prev: import ../pkgs { pkgs = prev; };
in
composeManyExtensions [ overlayPkgs ]
