# Based on:
# https://github.com/NixOS/nixpkgs/blob/ed142ab1b3a092c4d149245d0c4126a5d7ea00b0/pkgs/by-name/xr/xremap/package.nix
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xremap-niri";
  version = "0.14.9";

  src = fetchFromGitHub {
    owner = "xremap";
    repo = "xremap";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ftGg6xai4WbaoXmgNXW4RbpOWvIZMPhUlqWkg1xVin0=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildNoDefaultFeatures = true;
  buildFeatures = [ "niri" ];

  cargoHash = "sha256-eoCl5RQ5cNVEoOp8CA5Q/0xWnWcfKK1OvPNLOu/x9Dg=";

  meta = {
    description = "Key remapper for X11 and Wayland (Niri support).";
    homepage = "https://github.com/xremap/xremap";
    changelog = "https://github.com/xremap/xremap/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "xremap";
    platforms = lib.platforms.linux;
  };
})
