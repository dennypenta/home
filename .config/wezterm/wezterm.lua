local wezterm = require("wezterm")

return {
	-- keys
	-- skip_close_confirmation_for_processes_named = {
	-- 	"bash",
	-- 	"sh",
	-- 	"zsh",
	-- 	"lazygit",
	-- },
	leader = { key = "b", mods = "CMD", timeout_milliseconds = 1000 },
	keys = {
		-- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
		{ key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
		-- Make Option-Right equivalent to Alt-f; forward-word
		{ key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },

		-- { key = "Left", mods = "CMD", action = wezterm.action.SendString("\x1bOH") }, -- Home
		-- { key = "Right", mods = "CMD", action = wezterm.action.SendString("\x1bOF") }, -- End
		-- { key = "Backspace", mods = "CMD", action = wezterm.action.SendString("\x15") }, -- Delete line
		-- { key = "Backspace", mods = "ALT", action = wezterm.action.SendString("\x1b\x7f") }, -- Delete word
		{
			mods = "LEADER",
			key = "v",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			mods = "LEADER",
			key = "s",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "w",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		{
			key = "w",
			mods = "CMD",
			action = wezterm.action.CloseCurrentTab({ confirm = false }),
		},
		-- Move tabs left and right
		{ key = "{", mods = "SHIFT|ALT", action = wezterm.action.MoveTabRelative(-1) },
		{ key = "}", mods = "SHIFT|ALT", action = wezterm.action.MoveTabRelative(1) },

		{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
		{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
		{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },

		{ key = "-", mods = "CMD", action = wezterm.action.AdjustPaneSize({ "Left", 4 }) },
		{ key = "=", mods = "CMD", action = wezterm.action.AdjustPaneSize({ "Right", 4 }) },
		{ key = "+", mods = "CMD", action = wezterm.action.AdjustPaneSize({ "Down", 4 }) },
		{ key = "_", mods = "CMD", action = wezterm.action.AdjustPaneSize({ "Up", 4 }) },

		-- CTRL+SHIFT+ALT	LeftArrow	AdjustPaneSize={"Left", 1}
		-- CTRL+SHIFT+ALT	RightArrow	AdjustPaneSize={"Right", 1}
		-- CTRL+SHIFT+ALT	UpArrow	AdjustPaneSize={"Up", 1}
		-- CTRL+SHIFT+ALT	DownArrow	AdjustPaneSize={"Down", 1}
	},

	-- theme
	window_background_opacity = 0.88,
	font = wezterm.font_with_fallback({
		{ family = "Hack Nerd Font Mono", weight = "Regular", italic = false },
		{ family = "Hack Nerd Font Mono", weight = "Bold", italic = false },
		{ family = "Hack Nerd Font Mono", weight = "Regular", italic = true },
		{ family = "Hack Nerd Font Mono", weight = "Bold", italic = true },
	}),
	-- color_scheme = "nightfox",
	color_scheme = "Kanagawa Dragon (Gogh)",
	-- color_scheme ='Catppuccin Latte',
	font_size = 14.0,
}
