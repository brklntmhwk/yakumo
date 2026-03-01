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
      command = "${systedWideBinPath}/pidof hyprlock || ${systedWideBinPath}/hyprlock";
    }
    {
      event = "lock";
      command = "${systedWideBinPath}/pidof hyprlock || ${systedWideBinPath}/hyprlock";
    }
    {
      event = "after-resume";
      command = "niri msg action power-on-monitors";
    }
  ];
  timeouts = [
    {
      timeout = 150;
      command = "brightnessctl -s set 10";
      resumeCommand = "brightnessctl -r";
    }
    {
      timeout = 150;
      command = "brightnessctl -sd rgb:kbd_backlight set 0";
      resumeCommand = "brightnessctl -rd rgb:kbd_backlight";
    }
    {
      timeout = 300;
      command = "${systedWideBinPath}/pidof hyprlock || ${systedWideBinPath}/hyprlock";
    }
    {
      timeout = 330;
      command = "niri msg action power-off-monitors";
      resumeCommand = "niri msg action power-on-monitors && brightnessctl -r";
    }
    {
      timeout = 1800;
      command = "systemctl suspend";
    }
  ];
}
