{ theme }:

let
  inherit (theme) colors;
in
{
  # https://starship.rs/advanced-config/#style-strings
  add_newline = true;
  character = {
    success_symbol = "[ ➜](bold ${colors.green-cooler})";
    error_symbol = "[ ➜](bold ${colors.red-intense})";
  };
  username = {
    show_always = true;
    style_root = "bold ${colors.red-warmer}";
    style_user = "bold ${colors.cyan-faint}";
    format = "[$user]($style)@ ";
  };
}
