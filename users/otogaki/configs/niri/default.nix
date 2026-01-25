theme:

let
  inherit (theme) colors fonts cursorThemes;
in
{
  # https://yalter.github.io/niri/Configuration:-Input
  input = {
    keyboard.xkb = {

    };
    touchpad = {
      tap = { };
      natural-scroll = { };
      scroll-method = {
        _args = [ "two-finger" ];
      };
    };
    mouse.scroll-method = {
      _args = [ "no-scroll" ];
    };
    trackpoint.scroll-method = {
      _args = [ "on-button-down" ];
    };
    trackball.scroll-method = {
      _args = [ "on-button-down" ];
    };
    focus-follows-mouse = {
      _props.max-scroll-amount = "0%";
    };
  };

  # https://yalter.github.io/niri/Configuration:-Outputs
  # To confirm your monitor name, run `niri msg outputs`.
  output = [
    {
      _args = [ "DP-2" ];
      mode = {
        _args = [ "3840x2160" ];
      };
      scale = {
        _args = [ 2 ];
      };
      transform = {
        _args = [ "normal" ];
      };
      position = {
        _props = {
          x = 0;
          y = 0;
        };
      };
    }
    {
      _args = [ "HDMI-A-1" ];
      mode = {
        _args = [ "2560x1440" ];
      };
      scale = {
        _args = [ 1 ];
      };
      transform = {
        _args = [ "normal" ];
      };
      position = {
        _props = {
          x = 0;
          y = 2160;
        };
      };
    }
  ];

  # Cursor
  cursor = { };

  # TODO: Maybe change this to another one.
  # Environment Variables
  environment = {
    HYPRCURSOR_THEME = {
      _args = [ cursorThemes.hyprcursor.name ];
    };
    HYPRCURSOR_SIZE = {
      _args = [ 24 ];
    };
  };

  # https://yalter.github.io/niri/Configuration:-Layout
  layout = {
    gaps = {
      _args = [ 16 ];
    };
    center-focused-column = {
      _args = [ "never" ];
    };
    preset-column-widths = {
      proportion = [
        { _args = [ 0.33333 ]; }
        { _args = [ 0.5 ]; }
        { _args = [ 0.66667 ]; }
      ];
    };
    default-column-width = {
      proportion = {
        _args = [ 0.5 ];
      };
    };
    prefer-no-csd = { };
    focus-ring = {
      width = {
        _args = [ 4 ];
      };
      active-color = {
        _args = [ colors.blue-faint ];
      };
      inactive-color = {
        _args = [ colors.fg-dim ];
      };
    };
    border = {
      off = { };
      width = {
        _args = [ 4 ];
      };
      active-color = {
        _args = [ colors.yellow-faint ];
      };
      inactive-color = {
        _args = [ colors.fg-dim ];
      };
      urgent-color = {
        _args = [ colors.red ];
      };
    };
    shadow = {
      softness = {
        _args = [ 30 ];
      };
      spread = {
        _args = [ 5 ];
      };
      offset = {
        _props = {
          x = 0;
          y = 5;
        };
      };
      color = {
        _args = [ colors.bg-main ];
      };
    };
    struts = { };
  };

  # Startup Applications
  spawn-sh-at-startup = [
    { _args = [ "fcitx5 -d -r" ]; }
    { _args = [ "wl-paste --type text --watch cliphist store" ]; }
    { _args = [ "wl-paste --type image --watch cliphist store" ]; }
    { _args = [ "swww-daemon && swww img ${theme.wallpaper}" ]; }
    { _args = [ "emacsclient -c -a ''" ]; }
  ];
  spawn-at-startup = [
    { _args = [ "xwayland-satellite" ]; }
    { _args = [ "firefox" ]; }
    { _args = [ "wezterm" ]; }
  ];

  # Hotkey Overlay
  hotkey-overlay = {
    # skip-at-startup = {}; # Uncomment to disable popup
  };

  # Screenshots
  screenshot-path = {
    _args = [ "~/Pictures/Screenshots/%Y%m%d%H%M%S.png" ];
  };

  # https://yalter.github.io/niri/Configuration:-Animations
  animations = {
    workspace-switch.curve = {
      _args = [
        "cubic-bezier"
        0.22
        1.00
        0.36
        1.00
      ];
    };
    window-open = {
      duration-ms = {
        _args = [ 150 ];
      };
      curve = {
        _args = [ "ease-out-expo" ];
      };
    };
    window-close.curve = {
      _args = [
        "cubic-bezier"
        0.87
        0.00
        0.13
        1.00
      ];
    };
    window-movement.spring = {
      _props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
    window-resize.spring = {
      _props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
    horizontal-view-movement.spring = {
      _props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
    config-notification-open-close.spring = {
      _props = {
        damping-ratio = 0.6;
        stiffness = 1000;
        epsilon = 0.001;
      };
    };
    exit-confirmation-open-close.spring = {
      _props = {
        damping-ratio = 0.6;
        stiffness = 500;
        epsilon = 0.01;
      };
    };
    screenshot-ui-open = {
      duration-ms = {
        _args = [ 200 ];
      };
      curve = {
        _args = [ "ease-out-quad" ];
      };
    };
    overview-open-close.spring = {
      _props = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.0001;
      };
    };
  };

  # Workspaces
  workspace = [
    {
      _args = [ "home" ];
      open-on-output = {
        _args = [ "HDMI-A-1" ];
      };
    }
    {
      _args = [ "dev" ];
      open-on-output = {
        _args = [ "DP-2" ];
      };
    }
    {
      _args = [ "study" ];
      open-on-output = {
        _args = [ "HDMI-A-1" ];
      };
    }
  ];

  # https://yalter.github.io/niri/Configuration:-Window-Rules
  window-rule = [
    {
      match = [
        {
          _props = {
            at-startup = true;
          };
        }
        {
          _props = {
            app-id = "firefox";
          };
        }
      ];
      open-on-workspace = {
        _args = [ "study" ];
      };
      default-column-width.proportion = {
        _args = [ 0.5 ];
      };
    }
    {
      match = [
        {
          _props = {
            at-startup = true;
          };
        }
        {
          _props = {
            app-id = "^org\\.wezfurlong\\.wezterm$";
          };
        }
      ];
      open-on-workspace = {
        _args = [ "home" ];
      };
      default-column-width = { }; # Empty for workaround
    }
    {
      match = {
        _props = {
          app-id = "firefox$";
          title = "^Picture-in-Picture$";
        };
      };
      open-floating = {
        _args = [ true ];
      };
    }
  ];

  # Key Bindings
  binds = {
    "Mod+Shift+Slash" = {
      repeat = false;
      show-hotkey-overlay = { };
    };

    "Mod+T" = {
      repeat = false;
      _props.hotkey-overlay-title = "Open Wezterm";
      spawn = {
        _args = [ "wezterm" ];
      };
    };

    "Mod+D" = {
      repeat = false;
      _props.hotkey-overlay-title = "Open Wofi App Launcher";
      spawn = {
        _args = [
          "sh"
          "-c"
          "wofi --show drun"
        ];
      };
    };

    "Mod+Y" = {
      repeat = false;
      _props.hotkey-overlay-title = "Open Cliphist List via Wofi";
      spawn-sh = {
        _args = [ "cliphist list | wofi -S dmenu | cliphist decode | wl-copy" ];
      };
    };

    # System Control
    "Super+Ctrl+Alt+L" = {
      repeat = false;
      _props.hotkey-overlay-title = "Lock the Screen";
      spawn = {
        _args = [ "hyprlock" ];
      };
    };
    "Super+Ctrl+Alt+Comma" = {
      repeat = false;
      _props.hotkey-overlay-title = "Put the System to Sleep";
      spawn = {
        _args = [ "systemctl suspend" ];
      };
    };
    "Super+Ctrl+Alt+Shift+Comma" = {
      repeat = false;
      _props.hotkey-overlay-title = "Put the System to Hibernation";
      spawn = {
        _args = [ "systemctl hibernate" ];
      };
    };
    "Super+Ctrl+Alt+Period" = {
      repeat = false;
      _props.hotkey-overlay-title = "Shutdown the System";
      spawn = {
        _args = [ "systemctl poweroff" ];
      };
    };

    # Audio & Media
    "XF86AudioMicMute" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" ];
      };
    };
    "XF86AudioRaiseVolume" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" ];
      };
    };
    "XF86AudioLowerVolume" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" ];
      };
    };
    "XF86AudioMute" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ];
      };
    };
    "XF86AudioPlay" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "playerctl play-pause" ];
      };
    };
    "XF86AudioStop" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "playerctl stop" ];
      };
    };
    "XF86AudioPrev" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "playerctl previous" ];
      };
    };
    "XF86AudioNext" = {
      _props.allow-when-locked = true;
      spawn-sh = {
        _args = [ "playerctl next" ];
      };
    };

    # Brightness
    "XF86MonBrightnessUp" = {
      _props.allow-when-locked = true;
      spawn = {
        _args = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "+5%"
        ];
      };
    };
    "XF86MonBrightnessDown" = {
      _props.allow-when-locked = true;
      spawn = {
        _args = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "5%-"
        ];
      };
    };

    # Window/Column Management
    "Mod+O" = {
      repeat = false;
      toggle-overview = { };
    };
    "Mod+Q" = {
      repeat = false;
      close-window = { };
    };

    "Mod+Left" = {
      focus-column-left = { };
    };
    "Mod+Down" = {
      focus-window-down = { };
    };
    "Mod+Up" = {
      focus-window-up = { };
    };
    "Mod+Right" = {
      focus-column-right = { };
    };
    "Mod+B" = {
      focus-column-left = { };
    };
    "Mod+N" = {
      focus-window-down = { };
    };
    "Mod+P" = {
      focus-window-up = { };
    };
    "Mod+F" = {
      focus-column-right = { };
    };

    "Mod+Ctrl+Left" = {
      move-column-left = { };
    };
    "Mod+Ctrl+Down" = {
      move-window-down = { };
    };
    "Mod+Ctrl+Up" = {
      move-window-up = { };
    };
    "Mod+Ctrl+Right" = {
      move-column-right = { };
    };
    "Mod+Ctrl+B" = {
      move-column-left = { };
    };
    "Mod+Ctrl+N" = {
      move-window-down = { };
    };
    "Mod+Ctrl+P" = {
      move-window-up = { };
    };
    "Mod+Ctrl+F" = {
      move-column-right = { };
    };

    "Mod+Home" = {
      focus-column-first = { };
    };
    "Mod+End" = {
      focus-column-last = { };
    };
    "Mod+Ctrl+Home" = {
      move-column-to-first = { };
    };
    "Mod+Ctrl+End" = {
      move-column-to-last = { };
    };

    # Monitor Focus/Move
    "Mod+Shift+Left" = {
      focus-monitor-left = { };
    };
    "Mod+Shift+Down" = {
      focus-monitor-down = { };
    };
    "Mod+Shift+Up" = {
      focus-monitor-up = { };
    };
    "Mod+Shift+Right" = {
      focus-monitor-right = { };
    };
    "Mod+Shift+B" = {
      focus-monitor-left = { };
    };
    "Mod+Shift+N" = {
      focus-monitor-down = { };
    };
    "Mod+Shift+P" = {
      focus-monitor-up = { };
    };
    "Mod+Shift+F" = {
      focus-monitor-right = { };
    };

    "Mod+Shift+Ctrl+Left" = {
      move-column-to-monitor-left = { };
    };
    "Mod+Shift+Ctrl+Down" = {
      move-column-to-monitor-down = { };
    };
    "Mod+Shift+Ctrl+Up" = {
      move-column-to-monitor-up = { };
    };
    "Mod+Shift+Ctrl+Right" = {
      move-column-to-monitor-right = { };
    };
    "Mod+Shift+Ctrl+B" = {
      move-column-to-monitor-left = { };
    };
    "Mod+Shift+Ctrl+N" = {
      move-column-to-monitor-down = { };
    };
    "Mod+Shift+Ctrl+P" = {
      move-column-to-monitor-up = { };
    };
    "Mod+Shift+Ctrl+F" = {
      move-column-to-monitor-right = { };
    };

    # Workspace Focus/Move
    "Mod+Page_Down" = {
      focus-workspace-down = { };
    };
    "Mod+Page_Up" = {
      focus-workspace-up = { };
    };
    "Mod+U" = {
      focus-workspace-down = { };
    };
    "Mod+I" = {
      focus-workspace-up = { };
    };

    "Mod+Ctrl+Page_Down" = {
      move-column-to-workspace-down = { };
    };
    "Mod+Ctrl+Page_Up" = {
      move-column-to-workspace-up = { };
    };
    "Mod+Ctrl+U" = {
      move-column-to-workspace-down = { };
    };
    "Mod+Ctrl+I" = {
      move-column-to-workspace-up = { };
    };

    "Mod+Shift+Page_Down" = {
      move-workspace-down = { };
    };
    "Mod+Shift+Page_Up" = {
      move-workspace-up = { };
    };
    "Mod+Shift+U" = {
      move-workspace-down = { };
    };
    "Mod+Shift+I" = {
      move-workspace-up = { };
    };

    # Mouse Wheel
    "Mod+WheelScrollDown" = {
      _props.cooldown-ms = 150;
      focus-workspace-down = { };
    };
    "Mod+WheelScrollUp" = {
      _props.cooldown-ms = 150;
      focus-workspace-up = { };
    };
    "Mod+Ctrl+WheelScrollDown" = {
      _props.cooldown-ms = 150;
      move-column-to-workspace-down = { };
    };
    "Mod+Ctrl+WheelScrollUp" = {
      _props.cooldown-ms = 150;
      move-column-to-workspace-up = { };
    };

    "Mod+WheelScrollRight" = {
      focus-column-right = { };
    };
    "Mod+WheelScrollLeft" = {
      focus-column-left = { };
    };
    "Mod+Ctrl+WheelScrollRight" = {
      move-column-right = { };
    };
    "Mod+Ctrl+WheelScrollLeft" = {
      move-column-left = { };
    };

    "Mod+Shift+WheelScrollDown" = {
      focus-column-right = { };
    };
    "Mod+Shift+WheelScrollUp" = {
      focus-column-left = { };
    };
    "Mod+Ctrl+Shift+WheelScrollDown" = {
      move-column-right = { };
    };
    "Mod+Ctrl+Shift+WheelScrollUp" = {
      move-column-left = { };
    };

    # Number Keys (Workspaces)
    "Mod+1" = {
      focus-workspace = {
        _args = [ 1 ];
      };
    };
    "Mod+2" = {
      focus-workspace = {
        _args = [ 2 ];
      };
    };
    "Mod+3" = {
      focus-workspace = {
        _args = [ 3 ];
      };
    };
    "Mod+4" = {
      focus-workspace = {
        _args = [ 4 ];
      };
    };
    "Mod+5" = {
      focus-workspace = {
        _args = [ 5 ];
      };
    };
    "Mod+6" = {
      focus-workspace = {
        _args = [ 6 ];
      };
    };
    "Mod+7" = {
      focus-workspace = {
        _args = [ 7 ];
      };
    };
    "Mod+8" = {
      focus-workspace = {
        _args = [ 8 ];
      };
    };
    "Mod+9" = {
      focus-workspace = {
        _args = [ 9 ];
      };
    };

    "Mod+Ctrl+1" = {
      move-column-to-workspace = {
        _args = [ 1 ];
      };
    };
    "Mod+Ctrl+2" = {
      move-column-to-workspace = {
        _args = [ 2 ];
      };
    };
    "Mod+Ctrl+3" = {
      move-column-to-workspace = {
        _args = [ 3 ];
      };
    };
    "Mod+Ctrl+4" = {
      move-column-to-workspace = {
        _args = [ 4 ];
      };
    };
    "Mod+Ctrl+5" = {
      move-column-to-workspace = {
        _args = [ 5 ];
      };
    };
    "Mod+Ctrl+6" = {
      move-column-to-workspace = {
        _args = [ 6 ];
      };
    };
    "Mod+Ctrl+7" = {
      move-column-to-workspace = {
        _args = [ 7 ];
      };
    };
    "Mod+Ctrl+8" = {
      move-column-to-workspace = {
        _args = [ 8 ];
      };
    };
    "Mod+Ctrl+9" = {
      move-column-to-workspace = {
        _args = [ 9 ];
      };
    };

    "Mod+Tab" = {
      focus-workspace-previous = { };
    };

    # Advanced Column/Window Ops
    "Mod+BracketLeft" = {
      consume-or-expel-window-left = { };
    };
    "Mod+BracketRight" = {
      consume-or-expel-window-right = { };
    };
    "Mod+Comma" = {
      consume-window-into-column = { };
    };
    "Mod+Period" = {
      expel-window-from-column = { };
    };

    "Mod+R" = {
      switch-preset-column-width = { };
    };
    "Mod+Shift+R" = {
      switch-preset-window-height = { };
    };
    "Mod+Ctrl+R" = {
      reset-window-height = { };
    };
    "Mod+F" = {
      maximize-column = { };
    };
    "Mod+Shift+F" = {
      fullscreen-window = { };
    };
    "Mod+Ctrl+F" = {
      expand-column-to-available-width = { };
    };
    "Mod+C" = {
      center-column = { };
    };
    "Mod+Ctrl+C" = {
      center-visible-columns = { };
    };

    "Mod+Minus" = {
      set-column-width = {
        _args = [ "-10%" ];
      };
    };
    "Mod+Equal" = {
      set-column-width = {
        _args = [ "+10%" ];
      };
    };
    "Mod+Shift+Minus" = {
      set-window-height = {
        _args = [ "-10%" ];
      };
    };
    "Mod+Shift+Equal" = {
      set-window-height = {
        _args = [ "+10%" ];
      };
    };

    "Mod+V" = {
      toggle-window-floating = { };
    };
    "Mod+Shift+V" = {
      switch-focus-between-floating-and-tiling = { };
    };
    "Mod+W" = {
      toggle-column-tabbed-display = { };
    };

    # Screenshots
    "Print" = {
      screenshot = { };
    };
    "Ctrl+Print" = {
      screenshot-screen = { };
    };
    "Alt+Print" = {
      screenshot-window = { };
    };

    # Miscellaneous
    "Mod+Escape" = {
      _props.allow-inhibiting = false;
      toggle-keyboard-shortcuts-inhibit = { };
    };
    "Mod+Shift+E" = {
      quit = { };
    };
    "Ctrl+Alt+Delete" = {
      quit = { };
    };
    "Mod+Shift+P" = {
      power-off-monitors = { };
    };
  };
}
