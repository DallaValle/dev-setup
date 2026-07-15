# WezTerm

Same terminal on Windows and macOS: install WezTerm, then apply the shared config at `dotfiles/wezterm/.wezterm.lua`.
That file is one cross-platform Lua config, it detects the OS at runtime, so both machines get identical appearance and keybindings.
Only the default shell and launcher entries differ per OS.

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

- Shared: color scheme, font stack, window/tab-bar look, scrollback, pane split/nav keys, launcher (`Ctrl+Shift+L`).
- Windows only: WSL Ubuntu as default domain, PowerShell/cmd launcher entries, `Ctrl+Shift+P` (PowerShell tab) and `Ctrl+Shift+U` (Ubuntu tab).
- macOS only: login `zsh`/`bash` launcher entries, home dir as default cwd, `Ctrl+Shift+P` (zsh tab).
