# WezTerm

Same terminal and shell on Windows and macOS: WezTerm running zsh.
Install WezTerm, then apply the shared config at `dotfiles/wezterm/.wezterm.lua`.
That file is one cross-platform Lua config, it detects the OS at runtime, so both machines get identical appearance and keybindings.
The shell is zsh on both (config in [`../dotfiles/home/.zshrc`](../dotfiles/home/.zshrc)); only the launcher entries and new-tab keys differ per OS.

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
