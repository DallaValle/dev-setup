# VS Code

The GUI editor, installed once per *host* (macOS, Windows), never inside WSL.
The goal on both machines is the same: `code .` works in zsh and opens the current directory.

## macOS

Handled by `scripts/packages.sh`:

```sh
brew install --cask visual-studio-code
```

The script skips the install when `/Applications/Visual Studio Code.app` already exists, which covers an app that was drag-installed outside Homebrew.
It then symlinks the CLI bundled in the app into `~/.local/bin/code`:

```sh
ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ~/.local/bin/code
```

That symlink, not the Homebrew cask, is what makes `code .` work.
A cask install would put `code` in `/opt/homebrew/bin` on its own, but a manual app install leaves nothing on PATH, and linking it ourselves makes both cases behave the same.
`~/.local/bin` is already first on PATH via `dotfiles/home/.zshrc`, so a new shell picks it up.

## Windows (and WSL)

Install VS Code on the **Windows host**, not in the Ubuntu distro:

```powershell
winget install Microsoft.VisualStudioCode
```

Keep the installer's "Add to PATH" option enabled (it is on by default).
Then, in WSL, add the [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) from inside VS Code.

`code .` then works in zsh under WSL without a Linux VS Code build: WSL interop appends the Windows PATH to the Linux one, so `code` resolves to the Windows launcher script, which starts the Windows app and attaches its server to the distro.
The files stay on the Linux filesystem, and the window is a native Windows one.

Do not `apt install code` inside WSL. That installs a Linux GUI build that needs an X server and defeats the interop path above.

## Settings

Not tracked in this repo yet.
VS Code's own Settings Sync (sign in with GitHub) already carries settings, keybindings and extensions between the two machines, including into the WSL remote.
