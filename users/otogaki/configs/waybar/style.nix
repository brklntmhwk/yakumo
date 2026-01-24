theme:

let
  inherit (theme) colors fonts;
in
''
  /* Note that only a limited subset of CSS works properly in Waybar. */
  /* For more details, see: https://github.com/Alexays/Waybar/wiki/Styling#interactive-styling */
  /* You can consult this doc for supported CSS props: https://docs.gtk.org/gtk3/css-properties.html */

  /* Import the color scheme file generated with Wallust to use it */
  @import url("colors.css");

  * {
      font-family: "HackGen Console NF", JetBrains Mono, Roboto, Helvetica, Ariel, sans-serif;
      font-size: 15px;
  }

  /* Status bar  */
  window#waybar {
      background-color: rgba(43, 48, 59, 0.9);
      color: rgba(204, 204, 204, 1);
  }

  /* Module(s) on the left side */
  .modules-left {
      margin-left: 9px;
  }

  /* Module(s) on the right side */
  .modules-right {
      margin-right: 9px;
  }

  /* Custom app launcher module */
  #custom-launcher {
      font-size: 28px;
      margin-left: 15px;
      margin-right: 15px;
  }

  /* Hyprland workspaces module */
  #workspaces {
      color: transparent;
      margin-left: 8px;
      margin-right: 8px;
  }

  #workspaces button {
      background: transparent;
      min-width: 35px;
      border-bottom: 2px solid rgba(255, 255, 255, 0.5);
      border-radius: 3px;
      margin-left: 4px;
      margin-right: 4px;
  }

  #workspaces button.active {
      border-bottom: 2px solid rgba(255, 255, 255, 1);
  }

  #workspaces button:hover {
      background: rgba(147, 112, 208, 0.5);
  }

  /* Module to show running apps & programs */
  #taskbar {
      margin-left: 5px;
      margin-right: 5px;
  }

  #taskbar button {
      min-width: 140px;
      color: rgba(204, 204, 204, 0.8);
      background: transparent;
      border-bottom: 2px solid rgba(255, 255, 255, 0.3);
      margin-left: 2px;
      margin-right: 2px;
      padding-left: 3px;
      padding-right: 3px;
      padding-bottom: 2px;
  }

  #taskbar button.active {
      border-bottom: 2px solid rgba(255, 255, 255, 1);
  }

  #taskbar button:hover {
      color: rgba(204, 204, 204, 1);
      background: rgba(147, 112, 208, 0.5);
  }

  /* System control related modules  */
  #backlight,
  #battery,
  #clock,
  #language,
  #network,
  #tray,
  #pulseaudio {
      padding-left: 7px;
      padding-right: 7px;
  }

  #battery {

  }

  #clock {

  }

  #language {

  }

  #network {

  }

  #tray {

  }

  #pulseaudio {

  }
''
