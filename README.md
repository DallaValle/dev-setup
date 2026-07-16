# dev-setup

Sergio's dev machine setup: the programs to install and the config files that go with them.
Configs are tracked in git and symlinked into place, so editing a config *is* editing this repo and `git commit` is the whole sync workflow.

## Terminal and shell

Both machines run the same terminal and shell: **WezTerm** with **zsh**. Same appearance, keybindings, and prompt on Windows and macOS.

- Terminal: [`dotfiles/wezterm/.wezterm.lua`](dotfiles/wezterm/.wezterm.lua) - one cross-platform config, see [`programs/wezterm.md`](programs/wezterm.md).
- Shell: [`dotfiles/home/.zshrc`](dotfiles/home/.zshrc), set as the default login shell by [`scripts/packages.sh`](scripts/packages.sh).
- On Windows, WezTerm opens the WSL (Ubuntu) domain whose login shell is zsh; on macOS it opens the native zsh.

## Layout

| Path | What's in it |
|---|---|
| `programs/` | `programs.md` (the software the configs assume) plus a short wiki per program that needs manual setup, e.g. `wezterm.md` |
| `dotfiles/home/` | configs symlinked into `$HOME` on WSL/Linux and macOS (`.bashrc`, `.zshrc`, `.profile`, `.zprofile`, `.inputrc`, `.shell_aliases`, `.claude/`). `.bashrc` covers WSL/Linux, `.zshrc` covers macOS, and both source `.shell_aliases` for shell-agnostic aliases (e.g. `cc`) |
| `dotfiles/wezterm/` | `.wezterm.lua`, one cross-platform config applied to Windows and macOS (see `programs/wezterm.md`) |
| `dotfiles/windows/` | configs applied by hand on the Windows host (`.gitconfig`, `.wslconfig`) |
| `scripts/` | `packages.sh` (installs programs) and `install.sh` (symlinks the dotfiles) |

## Bootstrap on a new machine

```sh
git clone <this-repo> ~/dev-setup
cd ~/dev-setup
./scripts/packages.sh   # install programs (see programs/programs.md)
./scripts/install.sh    # symlink dotfiles/home into $HOME
```

Both scripts are idempotent, re-running them is safe.
`dotfiles/windows/` is applied manually because `install.sh` runs inside WSL and cannot write the Windows profile.
