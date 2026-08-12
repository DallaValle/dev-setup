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

Fixed on 2026-08-12, and the fix is automatic: the config clamps the terminal grid to 200x60, so no window can grow into the slow state.
Nothing to press any more, and `Win+Down` is no longer the workaround.

The cost driver is the **cell grid** (`cols` x `rows`), not the window's pixel area.
The two earlier rounds, on 2026-08-05 and 2026-08-06, had that backwards.
Measured with 400k lines of output, timed inside the window:

| Window | Grid | Pixels | Time |
| --- | --- | --- | --- |
| small | 120x43 | 1.25 Mpx | 2.0s |
| same pixels, smaller font | 264x107 | 1.28 Mpx | 6.1s |
| big window, huge font | 106x12 | 4.70 Mpx | 2.7s |
| big window, normal font | 418x53 | 5.36 Mpx | 5.8s to 12s |
| clamped by the config | 194x55 | 2.49 Mpx | 3.1s |

Two rows do the arguing: 4.4x the cells at the *same* pixel count costs 3x the time, while 3.7x the pixels at a tenth of the cells costs nothing.

That is why switching displays triggered it.
Dock, undock or drag the window to a panel with different scaling and WezTerm keeps the pixel size but re-derives the grid from the new DPI, so a 120x43 window comes back as a 200x65 one and every keystroke repaints all of it.
The clamp runs on `window-resized` and `window-config-reloaded`, restores a maximised window first (a maximised window ignores a resize), and converges in one pass with no flapping.
It only bites above 200x60, so a maximised 1920x1200 monitor (174x54) is left alone.

Measured against three displays at 1920x1200, scaled 125% / 125% / 100%, on a hybrid Intel Arc plus RTX 4070 laptop.
Check the live grid with `wezterm.exe cli list --format json`.

Already ruled out, do not re-diagnose: CPU and memory on both sides of WSL, `statusLine`, herdr logging and scrollback, disk and `/mnt/c` access, a maximised-by-default shortcut, moving a window between displays as a state bug in itself (a fresh window and a dragged one perform the same), and the `.wezterm.lua` dead ends (`front_end`, `webgpu_power_preference`, ligatures).
`max_fps` is the one knob that is a trade rather than a dead end: at 22k cells, dropping 120 to 30 halved the bulk-output time, but it also triples worst-case keystroke-to-pixel, so the config keeps 120 and clamps the grid instead.
