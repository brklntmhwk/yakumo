{ theme }:

let
  inherit (theme) colors fonts;
in
{
  # ---------------------------------------------------------
  # Variables
  # ---------------------------------------------------------
  "$hyperMod" = "SUPER + ALT + CTRL";
  "$superMod" = "SUPER";
  "$browser" = "zen";
  "$editor" = ''emacsclient -c -a ""'';
  "$fileManager" = "yazi";
  "$launcher" = "wofi --show drun";
  "$terminal" = "wezterm";

  # ---------------------------------------------------------
  # Monitors & Environment
  # ---------------------------------------------------------
  monitor = [ "HDMI-A-1, 2560x1440, 0x0, 1" ];

  env = [
    "HYPRCURSOR_THEME, ${theme.cursorThemes.hyprcursor.name}"
    "HYPRCURSOR_SIZE, 24"
    "XCURSOR_SIZE, 24"
    "GRIMBLAST_EDITOR, swappy -f"
    "GRIMBLAST_HIDE_CURSOR, 0"
  ];

  # ---------------------------------------------------------
  # Auto-Start (Exec-Once)
  # ---------------------------------------------------------
  exec-once = [
    "awww img ${theme.wallpaper}"
    "$terminal"
    "fcitx5 -d -r"
    "emacsclient -c -a ''"
    "wl-paste --type text --watch cliphist store"
    "wl-paste --type image --watch cliphist store"
    "[workspace name:Dev silent] $browser"
    "[workspace name:Writing silent] firefox"
    "[workspace special:Scratchpad silent] $terminal"
  ];

  # ---------------------------------------------------------
  # Core Configuration Sections
  # ---------------------------------------------------------
  # # https://wiki.hyprland.org/Configuring/Variables/#general=
  general = {
    gaps_in = 3;
    gaps_out = 8;
    gaps_workspaces = 0;
    border_size = 1;
    resize_on_border = true;
    extend_border_grab_area = 15;
  };

  # https://wiki.hyprland.org/Configuring/Variables/#misc
  misc = {
    disable_hyprland_logo = true;
    font_family = fonts.moralerspaceHw.name;
    force_default_wallpaper = 0;
    key_press_enables_dpms = true;
  };

  # https://wiki.hyprland.org/Configuring/Variables/#decoration
  decoration = {
    rounding = 1;
    rounding_power = 2.0;
  };

  # https://wiki.hyprland.org/Configuring/Variables/#input
  input = {
    follow_mouse = 2;
  };

  # https://wiki.hyprland.org/Configuring/Animations/
  animations = {
    enabled = true;
    bezier = [
      "easeOutExpo, 0.16, 1.00, 0.30, 1.00"
      "easeInOutExpo, 0.87, 0.00, 0.13, 1.00"
      "easeOutQuint, 0.22, 1.00, 0.36, 1.00"
      "easeOutCubic, 0.33, 1.00, 0.68, 1.00"
    ];
    animation = [
      "border, 1, 12, easeOutCubic"
      "fadeIn, 1, 12, easeOutExpo"
      "fadeOut, 1, 12, easeInOutExpo"
      "fadeDim, 1, 12, easeOutCubic"
      "workspaces, 1, 12, easeOutQuint"
    ];
  };

  # ---------------------------------------------------------
  # Key Bindings
  # ---------------------------------------------------------

  # -- Submaps (Must be sourced from a separate file due to ordering) --
  # source = [ "~/.config/hypr/submaps.conf" ];

  # -- Brightness --
  bindle = [
    ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
    ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
  ];

  # -- Audio --
  bind = [
    ", XF86AudioPlay, exec, playerctl play-pause"
    ", XF86AudioPrev, exec, playerctl previous"
    ", XF86AudioNext, exec, playerctl next"
    ", XF86AudioMute, exec, pamixer -t"
  ];
  binde = [
    ", XF86AudioRaiseVolume, exec, pamixer -i 5"
    ", XF86AudioLowerVolume, exec, pamixer -d 5"
  ];

  # -- General Binds (Combined List) --
  bind = [
    # Focus Navigation
    "$hyperMod, left, movefocus, l"
    "$hyperMod, right, movefocus, r"
    "$hyperMod, up, movefocus, u"
    "$hyperMod, down, movefocus, d"
    "$hyperMod, tab, cyclenext"
    "$hyperMod SHIFT, tab, cyclenext, prev"

    # Window Movement
    "$hyperMod, left, movewindow, l"
    "$hyperMod, right, movewindow, r"
    "$hyperMod, up, movewindow, u"
    "$hyperMod, down, movewindow, d"

    # Window Management
    "$hyperMod, Q, killactive,"

    # Power Management
    "$hyperMod, comma, exec, systemctl suspend"
    "$hyperMod SHIFT, comma, exec, systemctl hibernate"
    "$hyperMod, period, exec, systemctl poweroff"
    "$hyperMod, semicolon, exec, systemctl reboot"
    "$hyperMod, L, exec, hyprlock"

    # Program Launching
    "$superMod, A, exec, $launcher"
    "$superMod, B, exec, $browser"
    "$superMod, E, exec, $editor"
    "$superMod, F, exec, $fileManager"
    "$superMod, Z, exec, $terminal"

    # Screen Recording
    ''$superMod, R, exec, wl-screenrec -g "''${slurp}"''
    "$superMod SHIFT, R, exec, wl-screenrec -o HDMI-A-1"

    # Clipboard & Picker
    "$superMod, V, exec, cliphist list | wofi -S dmenu | cliphist decode | wl-copy"
    "$superMod SHIFT, C, exec, hyprpicker --autocopy"

    # Screenshots
    ", Print, exec, grimblast --notify edit area"
    "SHIFT, Print, exec, grimblast --notify edit active"
    "$superMod, Print, exec, grimblast --notify edit output"
    "$superMod SHIFT, Print, exec, grimblast --notify edit screen"

    # Workspaces
    "$hyperMod, E, workspace, name:Base"
    "$hyperMod, I, workspace, name:Dev"
    "$hyperMod, A, workspace, special:Scratchpad"
    "$hyperMod, O, workspace, name:Writing"
  ];

  # -- Mouse Bindings --
  bindm = [
    "$superMod, mouse:272, movewindow"
    "$superMod, mouse:273, resizewindow"
  ];

  # ---------------------------------------------------------
  # Workspace & Window Rules
  # ---------------------------------------------------------
  workspace = [
    "name:Base, monitor:HDMI-A-1, default:true"
    "name:Dev"
    "name:Writing"
    "special:Scratchpad"
  ];

  # windowrulev2 = [ ... ]; # Add rules here if needed
}
