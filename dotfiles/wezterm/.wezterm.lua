local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

local triple = wezterm.target_triple
local is_windows = triple:find("windows") ~= nil
local is_mac = triple:find("darwin") ~= nil

-- Appearance (shared on every OS)
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font_with_fallback({
	"Cascadia Code",
	"JetBrains Mono",
	"Menlo",
	"Consolas",
})
config.font_size = 11.0
config.window_background_opacity = 0.97
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- Tab bar (shared)
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false

-- Behavior (shared)
config.scrollback_lines = 10000
config.window_close_confirmation = "NeverPrompt"

-- Keybindings (shared)
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
	-- Launcher (Ctrl+Shift+L)
	{ key = "l", mods = "CTRL|SHIFT", action = act.ShowLauncher },
}

-- Platform-specific: default shell, launcher entries, new-tab keys
if is_windows then
	config.default_domain = "WSL:Ubuntu-20.04"
	config.wsl_domains = {
		{
			name = "WSL:Ubuntu-20.04",
			distribution = "Ubuntu-20.04",
			default_cwd = "/mnt/c/source",
		},
	}
	config.default_cwd = "C:/source"
	config.launch_menu = {
		{ label = "PowerShell 7", domain = { DomainName = "local" }, args = { "pwsh.exe", "-NoLogo" } },
		{ label = "Windows PowerShell", domain = { DomainName = "local" }, args = { "powershell.exe", "-NoLogo" } },
		{ label = "Command Prompt", domain = { DomainName = "local" }, args = { "cmd.exe" } },
		{ label = "Ubuntu (WSL)", domain = { DomainName = "WSL:Ubuntu-20.04" } },
	}
	-- New tabs: PowerShell / Ubuntu (WSL)
	table.insert(config.keys, {
		key = "p",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewTab({ domain = { DomainName = "local" }, args = { "pwsh.exe", "-NoLogo" } }),
	})
	table.insert(config.keys, {
		key = "u",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewTab({ domain = { DomainName = "WSL:Ubuntu-20.04" } }),
	})
elseif is_mac then
	config.default_cwd = wezterm.home_dir
	config.launch_menu = {
		{ label = "zsh", args = { "/bin/zsh", "-l" } },
		{ label = "bash", args = { "/bin/bash", "-l" } },
	}
	-- New tab: login zsh
	table.insert(config.keys, {
		key = "p",
		mods = "CTRL|SHIFT",
		action = act.SpawnCommandInNewTab({ args = { "/bin/zsh", "-l" } }),
	})
end

return config
