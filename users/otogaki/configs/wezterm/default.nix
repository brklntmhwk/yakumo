{ lib, theme }:

let
  inherit (builtins) genList toString;
  inherit (lib) generators;
  inherit (theme) colors fonts;
in {
  colors = {
    foreground = colors.fg-main;
    background = colors.bg-main;
    cursor_fg = colors.fg-main;
    # You don't need these unless `default_cursor_style` is set to either '{Steady|Blinking}Block'.
    # cursor_bg = colors.magenta-intense;
    # cursor_border = colors.magenta-intense;
    selection_fg = colors.fg-main;
    selection_bg = colors.bg-region;

    # When the IME, a dead key or a leader key are being processed and are effectively
    # holding input pending the result of input composition, change the cursor
    # to this color to give a visual cue about the compose state.
    compose_cursor = colors.red-warmer;

    # Colors for copy_mode and quick_select
    copy_mode_active_highlight_bg = { Color = colors.bg-hl-line; };
    copy_mode_active_highlight_fg = { Color = colors.fg-main; };
    copy_mode_inactive_highlight_bg = { Color = colors.bg-dim; };
    copy_mode_inactive_highlight_fg = { Color = colors.fg-dim; };
    quick_select_label_bg = { Color = colors.bg-hl-line; };
    quick_select_label_fg = { Color = colors.fg-main; };
  };
  font_size = 16.0;
  default_cursor_style = "SteadyBar";
  use_ime = true;
  window_background_opacity = 0.6;
  macos_window_background_blur = 10;
  window_padding = {
    left = 15;
    right = 15;
    top = 15;
    bottom = 15;
  };
  adjust_window_size_when_changing_font_size = false;
  switch_to_last_active_tab_when_closing_tab = true;

  # Use `mkLuaInline` to prevent these from being quoted as strings.
  font = generators.mkLuaInline ''
    wezterm.font_with_fallback({
      { family = "${fonts.hackgenNf.name}", weight = "Regular" },
      { family = "${fonts.jetbrainsMono.name}", weight = "Regular" },
    })
  '';

  # Key bindings
  leader = {
    key = "x";
    mods = "CTRL";
    timeout_milliseconds = 2000;
  };

  keys = [
    {
      key = "|";
      mods = "LEADER";
      action = generators.mkLuaInline
        "wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' })";
    }
    {
      key = "-";
      mods = "LEADER";
      action = generators.mkLuaInline
        "wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' })";
    }
    {
      key = "Tab";
      mods = "LEADER";
      action = generators.mkLuaInline "wezterm.action.ShowTabNavigator";
    }
    {
      key = "x";
      mods = "LEADER";
      action = generators.mkLuaInline "wezterm.action.ActivateCopyMode";
    }
    {
      key = "b";
      mods = "LEADER";
      action =
        generators.mkLuaInline "wezterm.action.AdjustPaneSize({ 'Left', 5 })";
    }
    {
      key = "f";
      mods = "LEADER";
      action =
        generators.mkLuaInline "wezterm.action.AdjustPaneSize({ 'Right', 5 })";
    }
    {
      key = "n";
      mods = "LEADER";
      action =
        generators.mkLuaInline "wezterm.action.AdjustPaneSize({ 'Down', 5 })";
    }
    {
      key = "p";
      mods = "LEADER";
      action =
        generators.mkLuaInline "wezterm.action.AdjustPaneSize({ 'Up', 5 })";
    }
  ]
  # You cannot use a Lua 'for' loop in a static table.
  # Instead, generate the list elements using Nix.
    ++ (genList (i: {
      key = toString (i + 1);
      mods = "LEADER";
      # Lua index in user config was (i - 1), so 0-based index for ActivateTab
      action =
        generators.mkLuaInline "wezterm.action.ActivateTab(${toString i})";
    }) 8);

  # WARNING: You cannot easily replicate `wezterm.gui.default_key_tables()` here
  # because Nix runs at build time and cannot query WezTerm's runtime defaults.
  # You must either hardcode the full table or omit inheritance.
  key_tables = {
    copy_mode = [
      {
        key = "b";
        mods = "NONE";
        action = generators.mkLuaInline "wezterm.action.CopyMode('MoveLeft')";
      }
      {
        key = "f";
        mods = "NONE";
        action = generators.mkLuaInline "wezterm.action.CopyMode('MoveRight')";
      }
      {
        key = "n";
        mods = "NONE";
        action = generators.mkLuaInline "wezterm.action.CopyMode('MoveDown')";
      }
      {
        key = "p";
        mods = "NONE";
        action = generators.mkLuaInline "wezterm.action.CopyMode('MoveUp')";
      }
    ];
  };
}
