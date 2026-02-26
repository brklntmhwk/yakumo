{
  coreutils,
  diffutils,
  fd,
  nixfmt,
  writeShellApplication,
}:

writeShellApplication {
  name = "yakumo-formatter";
  runtimeInputs = [
    coreutils
    diffutils
    nixfmt
    fd
  ];
  # Use double quotes as in ''${var} to escape bash variables in Nix multi-line strings.
  text = ''
    # Capture args passed by `nix fmt` as it passes the target directory or files
    # as args ($@).
    targets=("$@")

    # If no args are passed, default to the current directory.
    if [ ''${#targets[@]} -eq 0 ]; then
        targets=(".")
    fi

    files=()

    for target in "''${targets[@]}"; do
        if [ -f "$target" ]; then
            # Add a Nix file directly to the target list.
            if [[ "$target" == *.nix ]]; then
                files+=("$target")
            fi
        elif [ -d "$target" ]; then
            # Use `fd` to find all Nix files in a directory.
            while IFS= read -r file; do
                files+=("$file")
            done < <(fd --type file --extension nix --hidden --exclude .git . "$target")
        fi
    done

    total="''${#files[@]}"

    if [ "$total" -eq 0 ]; then
        echo "🙅 No Nix files found to format."
        exit 0
    fi

    echo "🔍️ Scanned $total Nix file(s)."
    echo "✨️ Formatting..."

    # Take a snapshot of file hashes BEFORE formatting.
    before_state=$(md5sum "''${files[@]}")

    # Run the formatter in one go.
    nixfmt "''${files[@]}"

    # Take a snapshot of file hashes AFTER formatting.
    after_state=$(md5sum "''${files[@]}")

    # Compare the states to check how many files were actually modified.
    modified_count=$(diff <(echo "$before_state") <(echo "$after_state") | grep -c "^>" || true)
    if [ "$modified_count" -eq 0 ]; then
        echo "⚖️ All $total file(s) were already formatted."
    else
        echo "✅️ Done! Formatted $modified_count out of $total file(s)."
    fi
  '';
}
