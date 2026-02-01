{ theme }:

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
      command = "loginctl lock-session";
    }
    {
      timeout = 330;
      command = "niri msg action power-off-monitors";
      # Combine waking monitors and restoring brightness from Hypridle config.
      resumeCommand = "niri msg action power-on-monitors && brightnessctl b-r";
    }
    {
      timeout = 1800;
      command = "systemctl suspend";
    }
  ];
}
