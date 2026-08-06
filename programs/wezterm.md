# WezTerm

Install WezTerm, then apply the shared config at `dotfiles/wezterm/.wezterm.lua`: one Lua file that detects the OS at runtime, so both machines get identical appearance and keybindings.
The shell it opens is zsh on both, configured in [`../dotfiles/home/.zshrc`](../dotfiles/home/.zshrc).

Apply = copy the file into place. It is a copy, not a symlink, so after editing the repo copy re-run the copy step to apply.

## Windows

```powershell
winget install wez.wezterm
Copy-Item "dotfiles\wezterm\.wezterm.lua" "$env:USERPROFILE\.wezterm.lua" -Force
```

## macOS

```sh
brew install --cask wezterm
cp dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua
```

## What is shared vs per-OS

- Shared: shell (zsh), color scheme, font stack, window/tab-bar look, scrollback, pane split/nav keys, launcher (`Ctrl+Shift+L`).
- Windows only: WSL Ubuntu as default domain (its login shell is zsh), PowerShell/cmd launcher entries, `Ctrl+Shift+P` (PowerShell tab) and `Ctrl+Shift+U` (Ubuntu tab).
- macOS only: native zsh, `zsh`/`bash` launcher entries, home dir as default cwd, `Ctrl+Shift+P` (zsh tab).

## Typing lag on the XPS

Investigated twice, on 2026-08-05 and 2026-08-06: the cause is a maximised window, and `Win+Down` is the fix.
Lag is proportional to window pixel area rather than cell count, so covering the 3840x2400 panel costs the latency: 1903x1100 px repainted per keystroke maximised, against 1309x924 windowed.
This is why the config sets `initial_cols` / `initial_rows`, which apply only to freshly spawned windows and so cannot survive a manual maximise.
Check the live size with `wezterm.exe cli list --format json`.

Already ruled out, do not re-diagnose: CPU and memory on both sides of WSL, `statusLine`, herdr logging and scrollback, disk and `/mnt/c` access, a maximised-by-default shortcut, and the `.wezterm.lua` dead ends (`max_fps`, `front_end`, `webgpu_power_preference`, ligatures).
