{
  # Make these align with Emacs navigation keybindings
  # See wofi(7) for more info about KEY
  key_up = "Ctrl-p";
  key_down = "Ctrl-n";
  key_left = "Ctrl-b";
  key_right = "Ctrl-f";
  # Make it appear wherever you want
  # See wofi(7) for more info about LOCATION
  location = "bottom-right";
  hide_scroll = true;
  # Let it shrunk to fit the number of visible lines
  dynamic_lines = true;
  # Let it not show the prompt in the search box(It shows the current mode by default)
  prompt = "Search keywords...";
  # Set the width
  width = "40%";
  # Enable fuzzy search
  matching = "fuzzy";
  # Allow case-insensitive search
  insensitive = true;
  # Show images in the clipboard history
  allow_images = true;
  # Set the image size
  image_size = 25;
}
