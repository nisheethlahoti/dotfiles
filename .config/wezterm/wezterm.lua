local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Ported verbatim from iTerm2 "Default" profile.
local scheme = wezterm.color.get_builtin_schemes()['Gruvbox dark, hard (base16)']
scheme.background = '#001818'
config.color_schemes = { custom = scheme }
config.color_scheme = 'custom'
local tab_bar_bg = '#284040'
config.colors = {
	tab_bar = {
		background         = tab_bar_bg,
		active_tab         = { bg_color = scheme.background, fg_color = scheme.foreground },
		inactive_tab       = { bg_color = '#183030', fg_color = scheme.foreground },
		inactive_tab_hover = { bg_color = '#385050', fg_color = scheme.foreground },
	}
}
config.window_frame = { active_titlebar_bg = tab_bar_bg, inactive_titlebar_bg = tab_bar_bg }

config.font = wezterm.font_with_fallback {
	{ family = 'FiraCode Nerd Font', weight = 450 --[[ Retina ]], harfbuzz_features = { 'calt=1' } },
	'Apple Color Emoji',
}
config.font_size = 14.0
config.default_cursor_style = 'SteadyBar'

config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 64
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

config.audible_bell = 'Disabled'
config.scrollback_lines = 50000
config.native_macos_fullscreen_mode = true

config.keys = {
	{ key = 'Enter', mods = 'CMD',       action = act.ToggleFullScreen },
	{ key = 'r',     mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
	{ key = 'd',     mods = 'CMD',       action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
	{ key = 'd',     mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
	{ key = '[',     mods = 'CMD',       action = act.ActivatePaneDirection 'Prev' },
	{ key = ']',     mods = 'CMD',       action = act.ActivatePaneDirection 'Next' },
	{
		key = 'k',
		mods = 'CMD',
		action = act.Multiple {
			act.ClearScrollback 'ScrollbackAndViewport', act.SendKey { key = 'L', mods = 'CTRL' },
		}
	},
	-- CMD+Shift+S: fuzzy launcher (attach to a mux domain).
	{ key = 's', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|DOMAINS' } },
	-- CMD+Shift+X: detach current pane's mux domain (remote stays running).
	{ key = 'x', mods = 'CMD|SHIFT', action = act.DetachDomain 'CurrentPaneDomain' },
}

-- Set the domain (local or SSHMUX:remote_server_name) as window title and tab background status
wezterm.on('format-window-title', function(tab) return 'WezTerm ' .. tab.active_pane.domain_name end)
wezterm.on('update-right-status', function(win, pane)
	local ok, name = pcall(function() return pane:get_domain_name() end)
	if ok then win:set_right_status(name .. '  ') end
end)

-- Open all new windows in fullscreen
wezterm.GLOBAL.fullscreened = wezterm.GLOBAL.fullscreened or {}
wezterm.on('window-config-reloaded', function(window)
	local id = tostring(window:window_id())
	if not wezterm.GLOBAL.fullscreened[id] then
		wezterm.GLOBAL.fullscreened[id] = true
		window:toggle_fullscreen()
	end
end)

return config
