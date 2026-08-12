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
	-- Rendering and input latency. All of it was measured on Windows only, against a
	-- hybrid Intel Arc + RTX laptop driving a 3840x2400 panel, so it stays scoped here.
	-- Opacity < 1.0 makes DWM alpha-composite every frame, and 3% transparency buys
	-- nothing; WebGpu (the default) lands on a slower Dx12 path than OpenGL here.
	-- Measured dead ends, do not re-add: forcing the RTX via webgpu_power_preference
	-- (the panel hangs off the iGPU, so it only adds a cross-adapter copy), disabling
	-- ligatures, front_end = "Software", and lowering scrollback_lines.
	config.window_background_opacity = 1.0
	config.front_end = "OpenGL"
	-- max_fps is a trade, not a dead end: at 22k cells, 400k lines took ~8.8s at 120 and
	-- ~4.9s at 30, because fewer frames repaint less. Keep 120 anyway - it buys the ~8ms
	-- keystroke-to-pixel that typing feels, and the grid clamp below removes the reason
	-- the frames got expensive in the first place.
	config.max_fps = 120
	config.animation_fps = 1 -- stop repainting cursor/background between frames
	config.cursor_blink_rate = 0 -- a blinking cursor keeps the GPU awake for no gain
	-- Lag tracks the cell grid (cols x rows), not the window's pixel area. Measured on
	-- 2026-08-12: 400k lines took 3.0s at 120x53 and 6.1s at 264x107 in the *same* 1.5Mpx
	-- window, while a 4.7Mpx window holding only 106x12 stayed at 2.7s.
	config.initial_cols = 120
	config.initial_rows = 42
	-- Which is why a display change hurt: dock, undock or drag to a panel with different
	-- scaling and WezTerm keeps the pixel size but re-derives the grid from the new DPI,
	-- so a 120x43 window came back as 206x65 crossing 125% to 100%, and every keystroke
	-- repaints all of it. Clamp the grid instead of relying on Win+Down by hand. 200x60
	-- leaves a maximised 1920x1200 monitor (174x54) alone and only bites above that.
	local MAX_COLS, MAX_ROWS = 200, 60
	local function clamp_grid(window)
		if window == nil then
			return
		end
		local ok, err = pcall(function()
			local dims = window:get_dimensions()
			if dims.is_full_screen then -- explicit intent, leave it be
				return
			end
			-- Tab size, not pane size: a split pane reports its own smaller grid.
			local size = window:mux_window():active_tab():get_size()
			if size.cols <= MAX_COLS and size.rows <= MAX_ROWS then
				return
			end
			-- Derive cell size from the live grid rather than from font metrics, so this
			-- holds at any DPI.
			local cell_w = size.pixel_width / size.cols
			local cell_h = size.pixel_height / size.rows
			window:restore() -- a maximised window ignores a resize until it is restored
			window:set_inner_size(
				math.floor(math.min(size.cols, MAX_COLS) * cell_w),
				math.floor(math.min(size.rows, MAX_ROWS) * cell_h)
			)
		end)
		if not ok then
			wezterm.log_error("clamp_grid: " .. tostring(err))
		end
	end
	wezterm.on("window-resized", clamp_grid)
	wezterm.on("window-config-reloaded", clamp_grid)
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
