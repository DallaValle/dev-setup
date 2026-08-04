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
| VS Code (`code`) | Windows, macOS | macOS: `scripts/packages.sh`; Windows: follow [`vscode.md`](vscode.md) | none tracked, VS Code Settings Sync handles it |
| Git | all | preinstalled / OS package manager | `dotfiles/windows/.gitconfig` |
| Claude Code | all | see docs.claude.com | `dotfiles/home/.claude/`, subagents in [`../agents/`](../agents/README.md) |
| grok (xAI CLI) | WSL/Linux, macOS | `scripts/packages.sh` | `~/.grok/AGENTS.md`, symlinked to the global `dotfiles/home/AGENTS.md` |
| herdr | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.config/herdr/config.toml` |
| treehouse | WSL/Linux, macOS | `scripts/packages.sh` | none tracked yet |

`packages.sh` also sets zsh as the default login shell (`chsh`), which is what makes WezTerm open zsh: on Windows the WSL domain launches the login shell, and on macOS the native shell is already zsh.

On macOS everything above is a Homebrew formula, except herdr, treehouse and grok (see below).
On WSL/Linux most come from apt, except `fd` (installed as `fdfind`, linked to `fd`) and `lazygit`/`neovim`, which `packages.sh` pulls from their official GitHub releases into `~/.local/bin` because apt's versions are missing or too old.
Neovim is pinned to `v0.10.4`, the last release that runs on Ubuntu 20.04 (focal, glibc 2.31); newer builds need glibc 2.32+.
Neovim's own plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), which bootstraps itself on first launch and installs everything from `dotfiles/home/.config/nvim/lazy-lock.json`.

[herdr](https://github.com/ogulcancelik/herdr), a terminal workspace manager for AI coding agents, and [treehouse](https://github.com/kunchenguid/treehouse), a pool of reusable git worktrees so several agents can work on one repo without re-cloning, are both single binaries installed from their official installer on both platforms.
herdr deliberately skips the Homebrew formula: brew builds it and its dependencies (llvm, rust, zig) from source, while the installer fetches a ready binary in seconds.
Neither is version-pinned, both self-update (`herdr update`, `treehouse update`), so `packages.sh` only bootstraps them.
herdr's config is tracked at `dotfiles/home/.config/herdr/config.toml`; it just rebinds pane focus to `prefix + arrow`, validate edits with `herdr config check`.
treehouse config would live at `~/.config/treehouse/config.toml` or `treehouse.toml` in a repo root, nothing tracked yet.

grok comes from its own installer too, into `~/.grok/bin`.
Its installer appends a PATH and completions block to `.zshrc`, which is a symlink into this repo, so that block is tracked here and the installer rewrites it in place rather than duplicating it.

treehouse does not run on Ubuntu 20.04: every upstream Linux build links `GLIBC_2.34` against focal's 2.31, back to v1.0.0, so there is nothing to pin to the way neovim is and `packages.sh` skips it below glibc 2.34.
Upgrading the WSL distro to 22.04+ unblocks it and retires the neovim pin at the same time.

VS Code is a GUI app, installed once per host and never inside WSL: Homebrew cask on macOS, `winget` on the Windows host where WSL reaches it through PATH interop, see [`vscode.md`](vscode.md).
