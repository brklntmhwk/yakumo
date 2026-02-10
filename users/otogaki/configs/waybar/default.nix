{
  "layer" = "bottom";
  "position" = "bottom";
  "height" = 46;
  "spacing" = 3;
  "reload_style_on_change" = true;

  "modules-left" = [ "custom/launcher" "hyprland/workspaces" "wlr/taskbar" ];

  "modules-center" = [ ];

  "modules-right" = [
    "backlight"
    "pulseaudio"
    "battery"
    "network"
    "tray"
    "hyprland/language"
    "clock"
  ];

  "custom/launcher" = {
    "format" = "";
    "on-click" = "wofi --show drun";
    "tooltip" = false;
  };

  "hyprland/workspaces" = {
    "icon-size" = 28;
    "spacing" = 3;
    "show-special" = true;
    "format" = "{icon}";

    "format-icons" = {
      "Base" = "🪹";
      "Dev" = "🛠️";
      "Writing" = "✍️";
      "Scratchpad" = "🚀";
    };

    "persistent-workspaces" = {
      "Base" = [ ];
      "Dev" = [ ];
      "Writing" = [ ];
      "Scratchpad" = [ ];
    };
  };

  "hyprland/language" = {
    "format" = "{}";
    "format-en" = "EN";
    "format-ja" = "JA";
  };

  "wlr/taskbar" = {
    "format" = "{icon} {title =.17}";
    "icon-size" = 29;
    "spacing" = 4;
    "tooltip-format" = "{title}";
    "on-click" = "activate";
    "on-click-middle" = "close";
    "on-click-right" = "minimize";
    "ignore-list" = [ "wezterm" ];
  };

  "clock" = {
    "format" = "     { =%R\n %d %b %Y}";
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
    "format-icons" = [ "" "" "" "" "" "" "" "" "" ];
  };

  "battery" = {
    "format" = "{icon} {capacity}%";
    "format-charging" = " {capacity}%";
    "format-charging" = "  {capacity}%";
    "format-icons" = [ "" "" "" "" "" ];
    "states" = {
      "warning" = 30;
      "critical" = 15;
    };
  };

  "network" = {
    "format-wifi" = "{icon}";
    "format-ethernet" = "";
    "format-disconnected" = "󰌙";
    "format-icons" = [ "󰤯" "󰤟" "󰤢" "󰤢" "󰤨" ];
    "tooltip-format" = "{ifname} {essid} ({signalStrength}%)";
  };

  "tray" = {
    "icon-size" = 18;
    "spacing" = 3;
    "show-passive-items" = true;
  };

  "pulseaudio" = {
    "format" = "{icon} {volume}%";
    "format-muted" = "󰝟 {volume}%";
    "format-icons" = {
      "default" = [ "󰕿" "󰖀" "󰕾" ];
      "headphone" = "󰋋";
      "headset" = "󰋋";
    };
    "tooltip-format" = "{desc}";
  };
}
