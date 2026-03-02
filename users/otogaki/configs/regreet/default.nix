{ theme }:

let
  inherit (theme) cursorThemes fonts loginThemes;
in
{
  background = {
    path = theme.wallpaper;
  };
  theme = {
    inherit (loginThemes.adwaita) name package;
    preferDark = true;
  };
  cursorTheme = {
    inherit (cursorThemes.adwaita) name package;
  };
  font = {
    inherit (fonts.moralerspaceHw) name package;
    size = 16;
  };
}
