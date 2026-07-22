# Programs

Software the tracked configs assume is present.
`scripts/packages.sh` installs the ones that can be automated, the rest are manual.

| Program | Platform | Install | Config |
|---|---|---|---|
| zsh + zsh-autosuggestions + zsh-syntax-highlighting | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.zshrc` |
| tmux | WSL/Linux, macOS | `scripts/packages.sh` | none tracked yet |
| ripgrep (`rg`) | WSL/Linux, macOS | `scripts/packages.sh` | none |
| fd | WSL/Linux, macOS | `scripts/packages.sh` | none |
| fzf | WSL/Linux, macOS | `scripts/packages.sh` | none |
| jq | WSL/Linux, macOS | `scripts/packages.sh` | none |
| lazygit | WSL/Linux, macOS | `scripts/packages.sh` | none |
| Neovim (`nvim`) | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.config/nvim/` (lazy.nvim, plugins pinned in `lazy-lock.json`) |
| WezTerm | Windows, macOS | follow [`wezterm.md`](wezterm.md) (same setup on both) | `dotfiles/wezterm/.wezterm.lua` |
| Git | all | preinstalled / OS package manager | `dotfiles/windows/.gitconfig` |
| Claude Code | all | see docs.claude.com | `dotfiles/home/.claude/` |
| herdr | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.config/herdr/config.toml` |

`packages.sh` also sets zsh as the default login shell (`chsh`), which is what makes WezTerm open zsh: on Windows the WSL domain launches the login shell, and on macOS the native shell is already zsh.

On macOS everything above is a Homebrew formula.
On WSL/Linux most come from apt, except `fd` (installed as `fdfind`, linked to `fd`) and `lazygit`/`neovim`, which `packages.sh` pulls from their official GitHub releases into `~/.local/bin` because apt's versions are missing or too old.
Neovim is pinned to `v0.10.4`, the last release that runs on Ubuntu 20.04 (focal, glibc 2.31); newer builds need glibc 2.32+.
Neovim's own plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which bootstraps itself on first launch and installs everything from `dotfiles/home/.config/nvim/lazy-lock.json`.

[herdr](https://github.com/ogulcancelik/herdr) is a terminal workspace manager for AI coding agents, shipped as a single binary.
On macOS it is a Homebrew formula; on WSL/Linux `packages.sh` runs herdr's official installer (`curl -fsSL https://herdr.dev/install.sh | sh`), which drops the right release binary into `~/.local/bin`.
It is not version-pinned like neovim: herdr updates itself in place with `herdr update` (and switches release channels with `herdr channel set stable|preview`), so `packages.sh` only bootstraps it and then stays out of the way.
Its config is tracked at `dotfiles/home/.config/herdr/config.toml` (symlinked to `~/.config/herdr/config.toml` by `install.sh`); currently it just rebinds pane focus to `prefix + arrow`. Validate edits with `herdr config check`.
