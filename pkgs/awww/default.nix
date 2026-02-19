# Based on:
# https://codeberg.org/LGFae/awww/src/commit/3877e25d8fcb8abff8879cba9a1db158d4502e27/flake.nix
{
  lib,
  fetchFromCodeberg,
  rustPlatform,
  installShellFiles,
  pkg-config,
  scdoc,
  libxkbcommon,
  lz4,
  wayland-scanner,
  wayland-protocols,
}:

rustPlatform.buildRustPackage rec {
  pname = "awww";
  # Clarify that this is not a versioned release but a snapshot for the quick fix.
  version = "0.11.2-unstable-2026-02-19";

  src = fetchFromCodeberg {
    owner = "LGFae";
    repo = "awww";
    # Commit: "rename project -> An Answer to your Wayland Wallpaper Woes".
    # Directly specify the commit hash because the latest release version (0.11.2)
    # doesn't contain the renaming as of Feb 2026.
    rev = "a132243eb4989c2cce22656b8f038bc8bf710f12";
    hash = "sha256-nusv5h1NwkVgjNdFeUFcWJcIjbWbCn+UM1Ee91svpS8=";
  };

  cargoHash = "sha256-epMjXCod90ftWzJyJwxBtbwcTvwoc/RRDLJbRCYzbcY=";

  nativeBuildInputs = [
    installShellFiles
    pkg-config
    scdoc
  ];

  buildInputs = [
    libxkbcommon
    lz4
    wayland-scanner
    wayland-protocols
  ];

  postInstall = ''
    for f in doc/*.scd; do
      local page="doc/$(basename "$f" .scd)"
      scdoc < "$f" > "$page"
      installManPage "$page"
    done

    installShellCompletion --cmd awww \
      --bash completions/awww.bash \
      --fish completions/awww.fish \
      --zsh completions/_awww
  '';

  meta = {
    description = "Efficient animated wallpaper daemon for wayland, controlled at runtime (formerly swww).";
    homepage = "https://codeberg.org/LGFae/awww";
    mainProgram = "awww";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
