{ systemWideBinPath }:

{
  general = {
    lock_cmd = "${systemWideBinPath}/pidof hyprlock || ${systemWideBinPath}/hyprlock";
    before_sleep_cmd = "loginctl lock-session";
    after_sleep_cmd = "${systemWideBinPath}/niri msg action power-on-monitors";
  };

  listener = [
    {
      timeout = 180; # 3 min
      on-timeout = "brightnessctl -s set 10";
      on-resume = "brightnessctl -r";
    }
    {
      timeout = 300; # 5 min
      on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
      on-resume = "brightnessctl -rd rgb:kbd_backlight";
    }
    {
      timeout = 480; # 8 min
      on-timeout = "loginctl lock-session";
    }
    {
      timeout = 600; # 10 min
      on-timeout = "${systemWideBinPath}/niri msg action power-off-monitors";
      on-resume = "${systemWideBinPath}/niri msg action power-on-monitors && brightnessctl -r";
    }
    {
      timeout = 1500; # 25 min
      on-timeout = "systemctl suspend";
    }
  ];
}
