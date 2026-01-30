{ theme }:

let
  inherit (theme) colors fonts;
in
{
  # --- General ---
  daemonize = true;
  ignore-empty-password = true;
  show-failed-attempts = true;
  show-keyboard-layout = true;

  # --- Background ---
  image = theme.wallpaper;
  scaling = "fill"; # 'center', 'fill', 'fit', 'stretch', or 'tile'

  # --- Typography ---
  font = fonts.moralerspaceHw.name;
  font-size = 24;

  # --- Indicator ---
  indicator-idle-visible = false;
  indicator-caps-lock = true;
  indicator-radius = 120;
  indicator-thickness = 10;
  line-uses-inside = true;

  # --- Styles ---
  text-color = colors.fg-main;
  text-clear-color = colors.yellow-intense; # When cleared
  text-ver-color = colors.green-intense; # When verifying
  text-wrong-color = colors.red-intense; # When invalid

  inside-color = colors.bg-dim;
  inside-clear-color = colors.bg-dim; # When cleared
  inside-ver-color = colors.bg-dim; # When verifying
  inside-wrong-color = colors.bg-dim; # When invalid

  line-color = colors.border;
  line-clear-color = colors.border; # When cleared
  line-ver-color = colors.border; # When verifying
  line-wrong-color = colors.border; # When invalid

  ring-color = colors.blue-faint;
  ring-clear-color = colors.yellow-faint; # When cleared
  ring-ver-color = colors.blue-faint; # When verifying
  ring-wrong-color = colors.red-faint; # When invalid

  caps-lock-bs-hl-color = colors.pink; # Color of backspace highlight segments when Caps Lock is active
  caps-lock-key-hl-color = colors.olive; # Color of the key press highlight segments when Caps Lock is active
}
