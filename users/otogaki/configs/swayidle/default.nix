# This is supposed to be used with Niri.
{ systemWideBinPath }:

{
  events = [
    # `loginctl lock-session` doesn't do its job, guiding us straight to the screen.
    # {
    #   event = "before-sleep";
    #   command = "loginctl lock-session";
    # }
    {
      event = "before-sleep";
      command = "${systemWideBinPath}/pidof hyprlock || ${systemWideBinPath}/hyprlock";
    }
    {
      event = "lock";
      command = "${systemWideBinPath}/pidof hyprlock || ${systemWideBinPath}/hyprlock";
    }
    {
      event = "after-resume";
      command = "${systemWideBinPath}/niri msg action power-on-monitors";
    }
  ];
  timeouts = [
    {
      timeout = 180; # seconds (3 min)
      command = "brightnessctl -s set 10";
      resumeCommand = "brightnessctl -r";
    }
    {
      timeout = 300; # seconds (5 min)
      command = "brightnessctl -sd rgb:kbd_backlight set 0";
      resumeCommand = "brightnessctl -rd rgb:kbd_backlight";
    }
    {
      timeout = 480; # seconds (8 min)
      command = "${systemWideBinPath}/pidof hyprlock || ${systemWideBinPath}/hyprlock";
    }
    {
      timeout = 600; # seconds (10 min)
      command = "${systemWideBinPath}/niri msg action power-off-monitors";
      resumeCommand = "${systemWideBinPath}/niri msg action power-on-monitors && brightnessctl -r";
    }
    {
      timeout = 1500; # seconds (25 min)
      command = "${systemWideBinPath}/systemctl suspend";
    }
  ];
}
