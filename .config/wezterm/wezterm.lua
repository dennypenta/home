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
			key = "-",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			mods = "LEADER",
			key = "=",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
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
		-- SHIFT + CTRL         LeftArrow          ->   ActivatePaneDirection(Left)
		-- SHIFT + CTRL         RightArrow         ->   ActivatePaneDirection(Right)
		-- SHIFT + CTRL         UpArrow            ->   ActivatePaneDirection(Up)
		-- SHIFT + CTRL         DownArrow          ->   ActivatePaneDirection(Down)

		-- CTRL+SHIFT+ALT	LeftArrow	AdjustPaneSize={"Left", 1}
		-- CTRL+SHIFT+ALT	RightArrow	AdjustPaneSize={"Right", 1}
		-- CTRL+SHIFT+ALT	UpArrow	AdjustPaneSize={"Up", 1}
		-- CTRL+SHIFT+ALT	DownArrow	AdjustPaneSize={"Down", 1}
	},

	-- theme
	window_background_opacity = 1.0,
	font = wezterm.font_with_fallback({
		{ family = "Hack Nerd Font Mono", weight = "Regular", italic = false },
		{ family = "Hack Nerd Font Mono", weight = "Bold", italic = false },
		{ family = "Hack Nerd Font Mono", weight = "Regular", italic = true },
		{ family = "Hack Nerd Font Mono", weight = "Bold", italic = true },
	}),
	color_scheme = "nightfox",
	font_size = 14.0,
}
