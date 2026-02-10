{ theme }:

let inherit (theme) colors fonts;
in {
  general = {
    hide_cursor = true;
    no_fade_in = false;
    no_fade_out = false;
    grace = 0;
    disable_loading_bar = false;
  };

  background = [{
    monitor = "";
    path = theme.wallpaper;
    blur_passes = 3;
    contrast = 0.8916;
    brightness = 0.8172;
    vibrancy = 0.1696;
    vibrancy_darkness = 0.0;
  }];

  image = [{
    monitor = "";
    path = theme.avator;
    border_size = 2;
    border_color = colors.border;
    size = 130;
    rounding = -1;
    rotate = 0;
    reload_time = -1;
    reload_cmd = "";
    position = "0, 40";
    halign = "center";
    valign = "center";
  }];

  shape = [{
    monitor = "";
    size = "300, 60";
    color = "rgba(255, 255, 255, .1)";
    rounding = 2;
    border_size = 0;
    border_color = "rgba(253, 198, 135, 0)";
    rotate = 0;
    xray = false;
    position = "0, -130";
    halign = "center";
    valign = "center";
  }];

  label = [
    # Date (Day, Month Date)
    {
      monitor = "";
      text = ''cmd[update:1000] echo -e "$(date +"%A, %B %d")"'';
      color = colors.fg-main;
      font_size = 25;
      font_family = fonts.moralerspaceHw.name;
      position = "0, 350";
      halign = "center";
      valign = "center";
    }
    # Time (Hour:Minute)
    {
      monitor = "";
      text = ''cmd[update:1000] echo "<span>$(date +"%I:%M")</span>"'';
      color = colors.fg-main;
      font_size = 120;
      font_family = fonts.moralerspaceHw.name;
      position = "0, 250";
      halign = "center";
      valign = "center";
    }
    # User Label
    {
      monitor = "";
      text = "  $USER";
      color = colors.fg-alt;
      outline_thickness = 2;
      dots_size = 0.2;
      dots_spacing = 0.2;
      dots_center = false;
      font_size = 18;
      font_family = fonts.moralerspaceHw.name;
      position = "0, -130";
      halign = "center";
      valign = "center";
    }
  ];

  input-field = [{
    monitor = "";
    size = "300, 60";
    outline_thickness = 2;
    dots_size = 0.2;
    dots_spacing = 0.2;
    dots_center = false;
    outer_color = colors.bg-dim;
    inner_color = colors.bg-dim;
    font_color = colors.fg-alt;
    fade_on_empty = false;
    font_family = fonts.moralerspaceHw.name;
    placeholder_text =
      ''<i><span foreground="${colors.fg-alt}">Enter Password...</span></i>'';
    hide_input = false;
    position = "0, -210";
    halign = "center";
    valign = "center";
    rounding = 2;
  }];
}
