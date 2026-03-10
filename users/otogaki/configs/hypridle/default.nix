# This is supposed to be used with Hyprland.
{ systemWideBinPath }:

{
  events = [
    {
      event = "lock";
      command = "pidof hyprlock || hyprlock";
    }
    {
      event = "before-sleep";
      command = "loginctl lock-session";
    }
    {
      event = "after-resume";
      command = "niri msg action power-on-monitors";
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
      command = "loginctl lock-session";
    }
    {
      timeout = 600; # seconds (10 min)
      command = "niri msg action power-off-monitors";
      resumeCommand = "niri msg action power-on-monitors && brightnessctl b-r";
    }
    {
      timeout = 1500; # seconds (25 min)
      command = "systemctl suspend";
    }
  ];
}
