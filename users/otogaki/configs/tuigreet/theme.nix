{ theme }:

let
  inherit (theme) colors;
in
{
  border = colors.magenta-warmer;
  text = colors.cyan-warmer;
  prompt = colors.green-warmer;
  time = colors.fg-main;
  action = colors.fg-alt;
  button = colors.gold;
  container = colors.bg-main;
  input = colors.fg-alt;
}
