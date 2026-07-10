local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Shell: WSL Ubuntu by default
config.default_domain = "WSL:Ubuntu-20.04"
config.wsl_domains = {
	{
		name = "WSL:Ubuntu-20.04",
		distribution = "Ubuntu-20.04",
		default_cwd = "/mnt/c/source",
	},
}

-- Appearance
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({
	"Cascadia Code",
	"JetBrains Mono",
	"Consolas",
})
config.font_size = 11.0
config.window_background_opacity = 0.97
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false

-- Behavior
config.scrollback_lines = 10000
config.window_close_confirmation = "NeverPrompt"
config.default_cwd = "C:/source"

-- Launcher entries (Ctrl+Shift+L to open)
config.launch_menu = {
	{ label = "PowerShell 7", domain = { DomainName = "local" }, args = { "pwsh.exe", "-NoLogo" } },
	{ label = "Windows PowerShell", domain = { DomainName = "local" }, args = { "powershell.exe", "-NoLogo" } },
	{ label = "Command Prompt", domain = { DomainName = "local" }, args = { "cmd.exe" } },
	{ label = "Ubuntu (WSL)", domain = { DomainName = "WSL:Ubuntu-20.04" } },
}

-- Keybindings
local act = wezterm.action
config.keys = {
	-- Pane splitting
	{ key = "d", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },
	-- Pane navigation
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Down") },
	-- Launcher
	{ key = "l", mods = "CTRL|SHIFT", action = act.ShowLauncher },
	-- New tabs: PowerShell (Windows) / Ubuntu (WSL)
	{
		key = "p",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewTab({
			domain = { DomainName = "local" },
			args = { "pwsh.exe", "-NoLogo" },
		}),
	},
	{
		key = "u",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewTab({ domain = { DomainName = "WSL:Ubuntu-20.04" } }),
	},
}

return config
