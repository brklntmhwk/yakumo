{ theme }:

let
  inherit (theme) cursorThemes fonts loginThemes;
in
{
  background = {
    path = theme.wallpaper;
  };
  theme = {
    name = loginThemes.adwaita.name;
    package = loginThemes.adwaita.package;
    preferDark = true;
  };
  cursorTheme = {
    name = cursorThemes.adwaita.name;
    package = cursorThemes.adwaita.package;
  };
  font = {
    name = fonts.moralerspaceHw.name;
    package = fonts.moralerspaceHw.package;
    size = 16;
  };
}
