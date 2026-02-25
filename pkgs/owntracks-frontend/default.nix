# Based on:
# https://github.com/imincik/bike-tracking/blob/36049776f7701438660da739c8776a5e6718ffcd/pkgs/owntracks-frontend/default.nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "owntracks-frontend";
  version = "9839b5acdd66cd7db5b86a82eb7be152fb50d6cc"; # v2.15.3

  src = fetchFromGitHub {
    owner = "owntracks";
    repo = "frontend";
    rev = finalAttrs.version;
    hash = "sha256-omNsCD6sPwPrC+PdyftGDUeZA8nOHkHkRHC+oHFC0eM=";
  };

  npmDepsHash = "sha256-sZkOvffpRoUTbIXpskuVSbX4+k1jiwIbqW4ckBwnEHM=";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r dist/* $out/share

    runHook postInstall
  '';

  meta = {
    description = "Web interface for OwnTracks.";
    homepage = "https://github.com/owntracks/frontend";
    changelog = "https://github.com/owntracks/frontend/blob/master/Changelog";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
