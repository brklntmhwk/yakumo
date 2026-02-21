{ theme }:

let
  inherit (theme) colors fonts;
in
''
  /* Note that only a limited subset of CSS works properly in Waybar. */
  /* For more details, see: https://github.com/Alexays/Waybar/wiki/Styling#interactive-styling */
  /* You can consult this doc for supported CSS props: https://docs.gtk.org/gtk3/css-properties.html */

  * {
      font-family: "${fonts.moralerspaceHw.name}", ${fonts.jetbrainsMono.name}, Roboto, Helvetica, Ariel, sans-serif;
      font-size: 15px;
  }

  /* Status bar  */
  window#waybar {
      background-color: ${colors.bg-lavender};
      color: ${colors.fg-main};
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
      border-bottom: 2px solid ${colors.bg-inactive};
      border-radius: 3px;
      margin-left: 4px;
      margin-right: 4px;
  }

  #workspaces button.active {
      border-bottom: 2px solid ${colors.bg-active};
  }

  #workspaces button:hover {
      background: ${colors.bg-active};
  }

  /* Module to show running apps & programs */
  #taskbar {
      margin-left: 5px;
      margin-right: 5px;
  }

  #taskbar button {
      min-width: 140px;
      color: ${colors.fg-main};
      background: transparent;
      border-bottom: 2px solid ${colors.bg-inactive};
      margin-left: 2px;
      margin-right: 2px;
      padding-left: 3px;
      padding-right: 3px;
      padding-bottom: 2px;
  }

  #taskbar button.active {
      border-bottom: 2px solid ${colors.bg-active};
  }

  #taskbar button:hover {
      color: ${colors.fg-main};
      background: ${colors.bg-active};
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
