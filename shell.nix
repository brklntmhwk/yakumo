{
  # Cover the legacy `nix-shell` without Nix Flakes enabled.
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "yakumo-shell";
  packages = builtins.attrValues {
    inherit (pkgs)
      nil
      statix
      age
      sops
      ;
  };
  shellHook = ''
    echo "☁️ Welcome to the Yakumo development sanctuary."
    echo "･Run 'nix fmt' to format the code."
    echo "･Run 'statix check' to lint your Nix code."
    echo "･Run 'sops secrets/default.yaml' to edit secrets."
  '';
}
