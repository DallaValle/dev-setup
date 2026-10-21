# Programs

Software the tracked configs assume is present.
`scripts/packages.sh` installs the ones that can be automated, the rest are manual.

## Version policy

**A new machine gets the latest version of everything.**
No pinning by default: apt and Homebrew resolve to current, the GitHub-release and official-installer paths fetch the newest build, and the self-updating tools keep themselves current.
A pin is an exception that has to earn its place, and each one carries the reason it exists and the condition that removes it.
Today there are no pins, only two programs skipped outright:

| Exception | Why | Retired when |
|---|---|---|
| treehouse not installed | every build needs glibc 2.34+, none older clears it | the WSL distro moves to 22.04+ |
| Google Chrome not installed on arm64 Linux | Google ships Linux builds for amd64 only | Google ships an arm64 Linux build |

## What gets installed

| Program | Platform | Install | Config |
|---|---|---|---|
| zsh + zsh-autosuggestions + zsh-syntax-highlighting | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.zshrc` |
| ripgrep (`rg`) | WSL/Linux, macOS | `scripts/packages.sh` | none |
| fd | WSL/Linux, macOS | `scripts/packages.sh` | none |
| fzf | WSL/Linux, macOS | `scripts/packages.sh` | none |
| jq | WSL/Linux, macOS | `scripts/packages.sh` | none |
| lazygit | WSL/Linux, macOS | `scripts/packages.sh` | none |
| Node.js (`node`, `npm`) | WSL/Linux, macOS | `scripts/packages.sh` | none |
| WezTerm | Windows, macOS | follow [`wezterm.md`](wezterm.md) (same setup on both) | `dotfiles/wezterm/.wezterm.lua` |
| VS Code (`code`) | Windows, macOS | macOS: `scripts/packages.sh`; Windows: follow [`vscode.md`](vscode.md) | none tracked, VS Code Settings Sync handles it |
| Git | all | preinstalled / OS package manager | `dotfiles/windows/.gitconfig` |
| Claude Code | all | see docs.claude.com | `dotfiles/home/.claude/`, subagents in [`../agents/`](../agents/README.md) |
| grok (xAI CLI) | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.grok/config.toml`; `~/.grok/AGENTS.md` is also linked to the global `dotfiles/home/AGENTS.md` |
| Codex (OpenAI CLI) | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.codex/config.toml`; `~/.codex/AGENTS.md` is linked to the global `dotfiles/home/AGENTS.md` |
| herdr | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.config/herdr/config.toml` |
| treehouse | WSL/Linux, macOS | `scripts/packages.sh` | none tracked yet |
| gh-axi, chrome-devtools-axi | WSL/Linux, macOS | `scripts/packages.sh` (npm global) | none; agents are pointed at them by the global `dotfiles/home/AGENTS.md` |
| Google Chrome | WSL/Linux | `scripts/packages.sh` (amd64 `.deb`) | none |

`packages.sh` also sets zsh as the default login shell (`chsh`), which is what makes WezTerm open zsh: on Windows the WSL domain launches the login shell, and on macOS the native shell is already zsh.

On macOS everything above is a Homebrew formula, except herdr, treehouse, grok and Codex (official installers), the AXI CLIs (npm) and Chrome (not installed, the existing app is used), see below.
On WSL/Linux most come from apt, except `fd` (installed as `fdfind`, linked to `fd`) and `lazygit`, which `packages.sh` pulls from its official GitHub release into `~/.local/bin` because apt's version is missing or too old.

[herdr](https://github.com/ogulcancelik/herdr), a terminal workspace manager for AI coding agents, and [treehouse](https://github.com/kunchenguid/treehouse), a pool of reusable git worktrees so several agents can work on one repo without re-cloning, are both single binaries installed from their official installer on both platforms.
herdr deliberately skips the Homebrew formula: brew builds it and its dependencies (llvm, rust, zig) from source, while the installer fetches a ready binary in seconds.
Neither is version-pinned, both self-update (`herdr update`, `treehouse update`), so `packages.sh` only bootstraps them.
herdr's config is tracked at `dotfiles/home/.config/herdr/config.toml`; it just rebinds pane focus to `prefix + arrow`, validate edits with `herdr config check`.
treehouse config would live at `~/.config/treehouse/config.toml` or `treehouse.toml` in a repo root, nothing tracked yet.

grok comes from its own installer too, into `~/.grok/bin`.
Its installer appends a PATH and completions block to `.zshrc`, which is a symlink into this repo, so that block is tracked here and the installer rewrites it in place rather than duplicating it.
Config lives at `dotfiles/home/.grok/config.toml` and is symlinked to `~/.grok/config.toml` by `install.sh`.

[Codex](https://github.com/openai/codex), OpenAI's coding agent CLI, also comes from its official installer (`chatgpt.com/codex/install.sh`) on both platforms.
It is a checksum verified static musl binary, so it needs no Node and has no glibc floor, and it lands in `~/.local/bin`, already on PATH, so the installer never edits the tracked `.zshrc`.
It updates itself, so `packages.sh` only bootstraps it.
Sign in once per machine with `codex login` and pick "Sign in with ChatGPT" to use a ChatGPT Plus or Pro plan instead of API credits; the token stays in `~/.codex/auth.json` and is never tracked.
`dotfiles/home/.codex/config.toml` configures the status line and is symlinked to `~/.codex/config.toml` by `install.sh`.

Node.js comes from Homebrew on macOS and, on WSL/Linux, from the newest LTS tarball on nodejs.org, unpacked into `~/.local/node`.
npm's global prefix stays inside that folder, so `npm install -g` needs no sudo and its bins land in `~/.local/node/bin`, which `.zshrc` puts ahead of the Windows npm that WSL interop exposes.
LTS is a release channel, not a pin: a fresh install always gets the newest one.

[AXI](https://github.com/kunchenguid/axi) is a set of design principles for agent first CLIs: compact TOON output, live state when run with no arguments, next step hints.
`packages.sh` installs the two official ones as npm globals, `gh-axi` (wraps `gh`, so `gh auth login` still applies) and `chrome-devtools-axi` (wraps chrome-devtools-mcp and drives a headless Chrome).
Both upgrade themselves with `<name> update`.
WSL has no browser of its own, so on Linux `packages.sh` also installs `google-chrome-stable` from Google's `.deb`, which registers Google's apt repo and keeps it current through apt; on macOS it uses the Chrome already installed.
Their optional `setup hooks` session hooks and `npx skills` stubs are deliberately not installed: the global `AGENTS.md` already tells agents to use them, at no per session token cost.

VS Code is a GUI app, installed once per host and never inside WSL: Homebrew cask on macOS, `winget` on the Windows host where WSL reaches it through PATH interop, see [`vscode.md`](vscode.md).
