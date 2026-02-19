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
  version = "0.11.2";

  src = fetchFromCodeberg {
    owner = "LGFae";
    repo = "awww";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  cargoHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

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
