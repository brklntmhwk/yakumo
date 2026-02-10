{
  modmap = [

  ];
  keymap = [{
    name = "Emacs-like Keybindings";
    application = { not = [ "Emacs" "wezterm" ]; };
    remap = {
      "C-b" = { with_mark = "left"; };
      "C-f" = { with_mark = "right"; };
      "C-p" = { with_mark = "up"; };
      "C-n" = { with_mark = "down"; };
      "M-b" = { with_mark = "C-left"; };
      "M-f" = { with_mark = "C-right"; };
      "C-a" = { with_mark = "home"; };
      "C-e" = { with_mark = "end"; };
      "C-d" = [ "delete" { with_mark = false; } ];
      "C-v" = { with_mark = "PageDown"; };
      "M-v" = { with_mark = "PageUp"; };
      "M-Shift-comma" = { with_mark = "C-home"; };
      "M-Shift-dot" = { with_mark = "C-end"; };
      "C-m" = "enter";
      "C-j" = "enter";
      "C-o" = [ "enter" "left" ];
      "C-w" = [ "C-x" { set_mark = false; } ];
      "M-w" = [ "C-c" { set_mark = false; } ];
      "C-y" = [ "C-v" { set_mark = false; } ];
      "Alt-backspace" = [ "C-backspace" { set_mark = false; } ];
      "C-slash" = [ "C-z" { set_mark = false; } ];
      "C-space" = { set_mark = true; };
      "C-s" = "C-f";
      "C-r" = "Shift-F3";
      "M-Shift-5" = "C-h";
      "C-g" = [ "esc" { set_mark = false; } ];
      "C-x" = {
        remap = {
          "h" = [ "C-home" "C-a" { set_mark = true; } ];
          "C-f" = "C-o";
          "C-s" = "C-s";
          "k" = "C-f4";
          "C-c" = "C-q";
          "u" = [ "C-z" { set_mark = false; } ];
        };
      };
    };
  }];
}
