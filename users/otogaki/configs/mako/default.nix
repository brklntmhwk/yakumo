{ theme }:

let
  inherit (theme) colors fonts;
in
{
  actions = true;
  anchor = "bottom-right";
  default-timeout = 5000; # Miliseconds.
  history = true;
  background-color = colors.bg-dim;
  border-color = colors.border;
  border-radius = 0;
  font = fonts.hackgenNf.name;
  icons = true;
}
