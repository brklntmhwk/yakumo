{ theme }:

let
  inherit (theme) cursorThemes fonts loginThemes;
in
{
  background = {
    path = theme.wallpaper;
  };
  theme = {
    inherit (loginThemes.adwaita) name;
    inherit (loginThemes.adwaita) package;
    preferDark = true;
  };
  cursorTheme = {
    inherit (cursorThemes.adwaita) name;
    inherit (cursorThemes.adwaita) package;
  };
  font = {
    inherit (fonts.moralerspaceHw) name;
    inherit (fonts.moralerspaceHw) package;
    size = 16;
  };
}
