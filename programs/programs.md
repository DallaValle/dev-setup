# Programs

Software the tracked configs assume is present.
`scripts/packages.sh` installs the ones that can be automated, the rest are manual.

## Version policy

**A new machine gets the latest version of everything.**
No pinning by default: apt and Homebrew resolve to current, the GitHub-release and official-installer paths fetch the newest build, and the self-updating tools keep themselves current.
A pin is an exception that has to earn its place, and each one carries the reason it exists and the condition that removes it.
There are no version pins. These programs are deliberately skipped:

| Exception | Why | Retired when |
|---|---|---|
| treehouse on Linux with glibc below 2.34 | every build needs glibc 2.34+ | the distro moves to glibc 2.34+ |
| Google Chrome not installed on arm64 Linux | Google ships Linux builds for amd64 only | Google ships an arm64 Linux build |
| Grok not installed | setup uses Codex and Claude Code | Grok is explicitly added back to the setup |

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
| WezTerm | Windows, macOS | macOS: `scripts/packages.sh`; Windows: follow [`wezterm.md`](wezterm.md) | `dotfiles/wezterm/.wezterm.lua`, copied by `bootstrap.sh` on macOS and manually on Windows |
| VS Code (`code`) | Windows, macOS | macOS: `scripts/packages.sh`; Windows: follow [`vscode.md`](vscode.md) | none tracked, VS Code Settings Sync handles it |
| Brave | macOS | `scripts/packages.sh` (Homebrew cask `brave-browser`) | none tracked |
| Tailscale | macOS | `scripts/packages.sh` (Homebrew cask `tailscale-app`) | none tracked; sign in after installation |
| Maccy | macOS | `scripts/packages.sh` (Homebrew cask `maccy`) | none tracked |
| Docker Desktop | macOS | `scripts/packages.sh` (Homebrew cask `docker-desktop`) | none tracked; open once to complete setup |
| KeepingYouAwake | macOS | `scripts/packages.sh` (Homebrew cask `keepingyouawake`) | none tracked |
| Git | all | macOS: `scripts/packages.sh` (Homebrew); elsewhere: OS package manager | `dotfiles/windows/.gitconfig` |
| GitHub CLI (`gh`) | macOS | `scripts/packages.sh` (Homebrew); elsewhere: follow [cli.github.com](https://cli.github.com/) | machine-local login via `gh auth login` |
| Claude Code | WSL/Linux, macOS | `scripts/packages.sh` (official native installer, latest channel) | `dotfiles/home/.claude/`, subagents in [`../agents/`](../agents/README.md) |
| Codex (OpenAI CLI) | WSL/Linux, macOS | `scripts/packages.sh` | `~/.codex/config.toml` links to a Git-ignored local repo file; `~/.codex/AGENTS.md` is linked to the global `dotfiles/home/AGENTS.md` |
| herdr | WSL/Linux, macOS | `scripts/packages.sh` | `dotfiles/home/.config/herdr/config.toml` |
| treehouse | WSL/Linux, macOS | `scripts/packages.sh` | none tracked yet |
| gh-axi, chrome-devtools-axi | WSL/Linux, macOS | `scripts/packages.sh` (npm global) | none; agents are pointed at them by the global `dotfiles/home/AGENTS.md` |
| Google Chrome | WSL/Linux, macOS | `scripts/packages.sh` (amd64 `.deb` on Linux, Homebrew cask on macOS) | none |

`packages.sh` also sets zsh as the default login shell (`chsh`), which is what makes WezTerm open zsh: on Windows the WSL domain launches the login shell, and on macOS the native shell is already zsh.

On macOS the shell tools use Homebrew formulae, and Brave, Tailscale, WezTerm, Maccy, VS Code, Docker Desktop, KeepingYouAwake and Chrome use Homebrew casks. Existing apps in `/Applications` or `~/Applications` are kept, including manual installs. herdr, treehouse, Codex and Claude Code use official installers, and the AXI CLIs use npm, see below.
On WSL/Linux most come from apt, except `fd` (installed as `fdfind`, linked to `fd`) and `lazygit`, which `packages.sh` pulls from its official GitHub release into `~/.local/bin` because apt's version is missing or too old.

[herdr](https://github.com/ogulcancelik/herdr), a terminal workspace manager for AI coding agents, and [treehouse](https://github.com/kunchenguid/treehouse), a pool of reusable git worktrees so several agents can work on one repo without re-cloning, are both single binaries installed from their official installer on both platforms.
herdr deliberately skips the Homebrew formula: brew builds it and its dependencies (llvm, rust, zig) from source, while the installer fetches a ready binary in seconds.
Neither is version-pinned, both self-update (`herdr update`, `treehouse update`), so `packages.sh` only bootstraps them.
herdr's config is tracked at `dotfiles/home/.config/herdr/config.toml`; it just rebinds pane focus to `prefix + arrow`, validate edits with `herdr config check`.
treehouse config would live at `~/.config/treehouse/config.toml` or `treehouse.toml` in a repo root, nothing tracked yet.

Grok is not installed or required by setup. Its tracked settings and shared skill links are retained for compatibility with existing installations.

[Codex](https://github.com/openai/codex), OpenAI's coding agent CLI, also comes from its official installer (`chatgpt.com/codex/install.sh`) on both platforms.
It is a checksum verified static musl binary, so it needs no Node and has no glibc floor, and it lands in `~/.local/bin`, already on PATH, so the installer never edits the tracked `.zshrc`.
It updates itself, so `packages.sh` only bootstraps it.
Sign in once per machine with `codex login` and pick "Sign in with ChatGPT" to use a ChatGPT Plus or Pro plan instead of API credits; the token stays in `~/.codex/auth.json` and is never tracked.
`~/.codex/config.toml` is deliberately not tracked: Codex writes MCP OAuth client secrets into it. `install.sh` adopts it into the Git-ignored `dotfiles/home/.codex/config.toml` and symlinks it back; provision it locally on each machine.

Node.js comes from Homebrew on macOS and, on WSL/Linux, from the newest LTS tarball on nodejs.org, unpacked into `~/.local/node`.
npm's global prefix stays inside that folder, so `npm install -g` needs no sudo and its bins land in `~/.local/node/bin`, which `.zshrc` puts ahead of the Windows npm that WSL interop exposes.
LTS is a release channel, not a pin: a fresh install always gets the newest one.

[AXI](https://github.com/kunchenguid/axi) is a set of design principles for agent first CLIs: compact TOON output, live state when run with no arguments, next step hints.
`packages.sh` installs the two official ones as npm globals, `gh-axi` (wraps `gh`, so `gh auth login` still applies) and `chrome-devtools-axi` (wraps chrome-devtools-mcp and drives a headless Chrome).
Both upgrade themselves with `<name> update`.
WSL has no browser of its own, so on Linux `packages.sh` also installs `google-chrome-stable` from Google's `.deb`, which registers Google's apt repo and keeps it current through apt. On macOS it installs the Chrome cask if the app is missing.
Their optional `setup hooks` session hooks and `npx skills` stubs are deliberately not installed: the global `AGENTS.md` already tells agents to use them, at no per session token cost.

VS Code is a GUI app, installed once per host and never inside WSL: Homebrew cask on macOS, `winget` on the Windows host where WSL reaches it through PATH interop, see [`vscode.md`](vscode.md).
