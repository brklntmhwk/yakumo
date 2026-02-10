{ theme }:

let inherit (theme) colors fonts;
in {
  actions = true;
  anchor = "bottom-right";
  background-color = colors.bg-dim;
  border-color = colors.border;
  border-radius = 0;
  font = fonts.hackgenNf.name;
  icons = true;
}
