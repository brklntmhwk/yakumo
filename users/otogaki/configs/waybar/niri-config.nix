{
  "layer" = "bottom";
  "position" = "bottom";
  "height" = 34;
  "spacing" = 5;
  "reload_style_on_change" = true;

  "modules-left" = [
    "custom/launcher"
  ];

  "modules-center" = [ ];

  "modules-right" = [
    "backlight"
    "pulseaudio"
    "battery"
    "network"
    "tray"
    "clock"
  ];

  "custom/launcher" = {
    "format" = "";
    "on-click" = "niri msg action spawn -- wofi --show drun";
    "tooltip" = false;
  };

  "clock" = {
    "format" = "     {:%R\n %d %b %Y}";
    "tooltip-format" = "<tt><small>{calendar}</small></tt>";
    "calendar" = {
      "mode" = "year";
      "mode-mon-col" = 3;
      "on-scroll" = 1;
      "on-click-right" = "mode";
      "weeks-pos" = "left";
      "format" = {
        "months" = "<span color='#b4befe'><b>{}</b></span>";
        "days" = "<span color='#ecc6d9'><b>{}</b></span>";
        "weeks" = "<span color='#99ffdd'><b>W{}</b></span>";
        "weekdays" = "<span color='#a6adc8'><b>{}</b></span>";
        "today" = "<span color='#f38ba8'><b><u>{}</u></b></span>";
      };
    };
    "actions" = {
      "on-click-right" = "mode";
      "on-click-forward" = "tz_up";
      "on-click-backward" = "tz_down";
      "on-scroll-up" = "shift_up";
      "on-scroll-down" = "shift_down";
    };
  };

  "backlight" = {
    "format" = "{percent}% {icon}";
    "format-icons" = [
      ""
      ""
      ""
      ""
      ""
      ""
      ""
      ""
      ""
    ];
  };

  "battery" = {
    "format" = "{icon} {capacity}%";
    "format-charging" = " {capacity}%";
    "format-icons" = [
      ""
      ""
      ""
      ""
      ""
    ];
    "states" = {
      "warning" = 30;
      "critical" = 15;
    };
  };

  "network" = {
    "format-wifi" = "{icon}";
    "format-ethernet" = "";
    "format-disconnected" = "󰌙";
    "format-icons" = [
      "󰤯"
      "󰤟"
      "󰤢"
      "󰤢"
      "󰤨"
    ];
    "tooltip-format" = "{ifname} {essid} ({signalStrength}%)";
  };

  "tray" = {
    "icon-size" = 20;
    "spacing" = 3;
    "show-passive-items" = true;
  };

  "pulseaudio" = {
    "format" = "{icon} {volume}%";
    "format-muted" = "󰝟 {volume}%";
    "format-icons" = {
      "default" = [
        "󰕿"
        "󰖀"
        "󰕾"
      ];
      "headphone" = "󰋋";
      "headset" = "󰋋";
    };
    "tooltip-format" = "{desc}";
  };
}
