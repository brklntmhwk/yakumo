local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Theme
config.color_scheme = "Whimsy"
-- config.color_scheme = 'Wallust'

-- Font
config.font = wezterm.font_with_fallback({
	{ family = "HackGen Console", weight = "Regular" },
	{ family = "JetBrains Mono", weight = "Regular" },
})
config.font_size = 16.0

-- IME
config.use_ime = true

-- Window style
config.window_background_opacity = 0.6
config.macos_window_background_blur = 10

-- Padding
config.window_padding = {
	left = 15,
	right = 15,
	top = 15,
	bottom = 15,
}

-- Key customization
config.leader = { key = "x", mods = "CTRL", timeout_milliseconds = 2000 } -- Emacs style

config.keys = {
	{ key = "|", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "Tab", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "x", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "b", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "f", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "n", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "p", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
}

for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- https://wezterm.org/config/lua/wezterm.gui/default_key_tables.html
local copy_mode = {}
if wezterm.gui then
	copy_mode = wezterm.gui.default_key_tables().copy_mode
	-- Emacs navigation style
	table.insert(copy_mode, {
		key = "b",
		mods = "NONE",
		action = act.CopyMode("MoveLeft"),
	})
	table.insert(copy_mode, {
		key = "f",
		mods = "NONE",
		action = act.CopyMode("MoveRight"),
	})
	table.insert(copy_mode, {
		key = "n",
		mods = "NONE",
		action = act.CopyMode("MoveDown"),
	})
	table.insert(copy_mode, {
		key = "p",
		mods = "NONE",
		action = act.CopyMode("MoveUp"),
	})
end

config.key_tables = {
	copy_mode = copy_mode,
}

-- Misc
config.adjust_window_size_when_changing_font_size = false
config.switch_to_last_active_tab_when_closing_tab = true

return config
