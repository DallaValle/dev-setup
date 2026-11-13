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

`scripts/packages.sh` installs the app automatically, skipping an existing installation. `scripts/bootstrap.sh` also copies the config, backing up a differing local file first. When running only the package and config sync scripts, copy the config yourself:

```sh
cp dotfiles/wezterm/.wezterm.lua ~/.wezterm.lua
```

`Cmd+V` pastes text normally. When the clipboard offers a PNG or TIFF image, it sends `Ctrl+V` so an application with clipboard image support can attach it. This requires the application to run locally and support that shortcut. `Ctrl+Shift+V` remains available for terminal text paste.

The font is JetBrains Mono, bundled with WezTerm, so no separate font installation is needed. It is 14pt on macOS and 11pt on Windows, because macOS renders points smaller.

## What is shared vs per-OS

- Shared: shell (zsh), color scheme, font stack, window/tab-bar look, scrollback, pane split/nav keys, launcher (`Ctrl+Shift+L`).
- Windows only: WSL Ubuntu as default domain (its login shell is zsh), PowerShell/cmd launcher entries, `Ctrl+Shift+P` (PowerShell tab) and `Ctrl+Shift+U` (Ubuntu tab).
- macOS only: native zsh, `zsh`/`bash` launcher entries, home dir as default cwd, `Ctrl+Shift+P` (zsh tab).
