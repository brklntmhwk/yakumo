{ pkgs, self }:

{
  yosuga = pkgs.callPackage ./nixos/yosuga.nix { inherit self; };
}
