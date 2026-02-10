{ theme }:

let inherit (theme) colors fonts;
in {
  yazi = {
    # Manager
    mgr = {
      ratio = [ 2 3 3 ];
      sort_by = "natural";
      sort_sensitive = true;
      sort_reverse = false;
      sort_dir_first = true;
      sort_translit = false;
      line_mode = "size";
      show_hidden = true;
      show_symlink = true;
      scrolloff = 5;
      mouse_event = [ "click" "scroll" ];
      title_format = "Yazi: {cwd}";
    };
    preview = {
      wrap = "no";
      tab_size = 2;
      max_width = 600;
      max_height = 900;
      cache_dir = "";
      image_delay = 30;
      image_filter = "triangle";
      image_quality = 75;
      sixel_fraction = 15;
      ueberzug_scale = 1;
      ueberzug_offset = [ 0 0 0 0 ];
    };
  };
  keymap = {
    mgr = {
      prepend_keymap = [
        # Navigation (Next/Previous Line)
        {
          on = [ "<C-n>" ];
          run = "arrow 1";
          desc = "Move down";
        }
        {
          on = [ "<C-p>" ];
          run = "arrow -1";
          desc = "Move up";
        }

        # Navigation (Enter/Leave Directory)
        {
          on = [ "<C-f>" ];
          run = "enter";
          desc = "Enter directory";
        }
        {
          on = [ "<C-b>" ];
          run = "leave";
          desc = "Leave directory";
        }

        # Paging (Scroll Down/Up)
        {
          on = [ "<C-v>" ];
          run = "arrow 50%";
          desc = "Scroll down";
        }
        {
          on = [ "<A-v>" ];
          run = "arrow -50%";
          desc = "Scroll up";
        }

        # Jumping (Top/Bottom)
        {
          on = [ "<A-<>" ];
          run = "arrow top";
          desc = "Move to top";
        }
        {
          on = [ "<A->>" ];
          run = "arrow bot";
          desc = "Move to bottom";
        }

        # Actions
        {
          on = [ "<C-g>" ];
          run = "escape";
          desc = "Cancel selection/Exit";
        }
        {
          on = [ "<C-s>" ];
          run = "search --via=fd";
          desc = "Search files via fd";
        }

        # Start/End of line (Mapped to Top/Bottom of view for utility)
        {
          on = [ "<C-a>" ];
          run = "arrow -99999999";
          desc = "Move to top";
        }
        {
          on = [ "<C-e>" ];
          run = "arrow 99999999";
          desc = "Move to bottom";
        }
      ];
    };
  };
}
