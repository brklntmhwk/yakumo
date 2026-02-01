{ theme }:

let
  inherit (builtins) attrValues;
  inherit (theme) colors;
in
{
  flags = {
    hide_avg_cpu = true;
    temperature_type = "celsius";
  };
  styles = {
    battery = {
      high_battery_color = colors.green;
      medium_battery_color = colors.yellow;
      low_battery_color = colors.red;
    };
    cpu = {
      all_entry_color = colors.green;
      avg_entry_color = colors.red;
      cpu_core_colors = attrValues {
        inherit (colors)
          magenta-warmer
          yellow-warmer
          cyan-warmer
          green-warmer
          blue-warmer
          cyan
          green
          blue
          ;
      };
    };
    graphs = {
      legend_text = colors.fg-main;
      graph_color = colors.bg-graph-magenta-0;
    };
    memory = {
      ram_color = colors.magenta-warmer;
      cache_color = colors.red-warmer;
      swap_color = colors.yellow-warmer;
      arc_color = colors.cyan-warmer;
      gpu_colors = attrValues {
        inherit (colors)
          blue-warmer
          red-warmer
          cyan
          gree
          blue
          red
          ;
      };
    };
    network = {
      rx_color = colors.magenta-warmer;
      tx_color = colors.yellow-warmer;
      rx_total_color = colors.cyan-warmer;
      tx_total_color = colors.green-warmer;
    };
    tables = {
      headers = {
        color = colors.magenta-intense;
        bold = true;
      };
    };
    widgets = {
      border_color = colors.border;
      selected_border_color = colors.magenta-faint;
      widget_title.color = colors.fg-main;
      text = colors.fg-main;
      selected_text = {
        color = colors.fg-dim;
        bg_color = colors.magenta-faint;
      };
      disabled_text.color = colors.fg-dim;
    };
  };
}
