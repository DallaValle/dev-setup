# dev-setup

Sergio's dev machine setup: the programs to install and the config files that go with them.
Configs are tracked in git and symlinked into place, so editing a config *is* editing this repo and `git commit` is the whole sync workflow.

## Terminal and shell

Both machines run the same terminal and shell: **WezTerm** with **zsh**. Same appearance, keybindings, and prompt on Windows and macOS.

- Terminal: [`dotfiles/wezterm/.wezterm.lua`](dotfiles/wezterm/.wezterm.lua), one cross-platform config, see [`programs/wezterm.md`](programs/wezterm.md).
- Shell: [`dotfiles/home/.zshrc`](dotfiles/home/.zshrc), set as the default login shell by [`scripts/packages.sh`](scripts/packages.sh).
- On Windows, WezTerm opens the WSL (Ubuntu) domain whose login shell is zsh; on macOS it opens the native zsh.

## Layout

| Path | What's in it |
|---|---|
| `AGENTS.md` | the rule set every agent working *on this repo* reads, at the root so agents that auto-discover it need no wiring. Claude Code reaches it through the one-line import in `.claude/CLAUDE.md` |
| `agents/` | `sub-agents/`, the shelf of curated subagents, deliberately not deployed. Explained in [`agents/README.md`](agents/README.md) |
| `programs/` | `programs.md` (the software the configs assume) plus a short wiki per program that needs manual setup by hand on a Windows or macOS host: `wezterm.md`, `vscode.md`. Nothing else belongs here |
| `dotfiles/home/` | configs symlinked into `$HOME` on WSL/Linux and macOS (`.zshrc`, `.zshenv`, `.bashrc`, `.profile`, `.zprofile`, `.inputrc`, `.config/herdr/config.toml`, `.claude/`, `.agents/skills/`, `.codex/config.toml`, `.grok/config.toml`, `AGENTS.md`). `.zshrc` is the one cross-platform shell config, aliases included; `.bashrc` is only a fallback for bash sessions. `AGENTS.md` here is the *global* rule set, linked to every agent's expected filename by `install.sh`, and `.claude/agents/` is where a subagent goes to become globally active (see [`agents/README.md`](agents/README.md)) |
| `dotfiles/wezterm/` | `.wezterm.lua`, copied rather than symlinked because it lands on the Windows and macOS host, not in WSL |
| `dotfiles/windows/` | configs applied by hand on the Windows host (`.gitconfig`, `.wslconfig`) |
| `templates/` | reusable project files kept here to iterate on the best version, copied by hand into each repo: `PULL_REQUEST_TEMPLATE.md` goes to `.github/` |
| `scripts/` | `bootstrap.sh` (complete macOS setup), `packages.sh` (installs programs), `install.sh` (symlinks the dotfiles), `check.sh` (checks the macOS installation) |

## Bootstrap on a new machine

**The PC setup is done by a local agent: Codex or Claude Code.** You install and sign in to one agent; it installs prerequisites, clones this repo, applies the setup and verifies the result.

### 1. Start one agent before cloning

On a new Mac, finish macOS setup, connect to the internet, and open Terminal as your normal administrator user. Homebrew, Node.js, Git and SSH keys are not required for this first step. Choose **one** option.

**[Codex CLI](https://learn.chatgpt.com/docs/codex/cli):** install it, [sign in with ChatGPT](https://learn.chatgpt.com/docs/auth), then start:

```sh
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
export PATH="$HOME/.local/bin:$PATH"
codex login
codex --dangerously-bypass-approvals-and-sandbox
```

**[Claude Code](https://code.claude.com/docs/en/quickstart):** install it, then start and complete its browser sign-in when prompted:

```sh
curl -fsSL https://claude.ai/install.sh | bash -s -- latest
export PATH="$HOME/.local/bin:$PATH"
claude --dangerously-skip-permissions
```

These launch commands use the same unattended mode as the repo's `cx` and `cc` aliases. Complete any first-run prompts. If an agent is already installed, start it directly.

### 2. Give the agent this prompt

Use the same prompt with either agent:

```text
Set up this new Mac using https://github.com/DallaValle/dev-setup.git.
1. Check Xcode Command Line Tools. If missing, start xcode-select --install
   and wait for me to finish the Apple installer.
2. Install Homebrew if missing using its official installer, load brew shellenv
   into your current environment, and install git and gh.
3. Check GitHub authentication. If needed, run gh auth login with HTTPS and
   browser login, then gh auth setup-git. I will complete the browser sign-in.
4. Clone the repo into ~/dev-setup. If it already exists, inspect its status
   first and preserve local changes. Read AGENTS.md and README.md.
5. Run ./scripts/bootstrap.sh from the repo. Fix setup failures and rerun
   until ./scripts/check.sh passes. Verify commands in a new login zsh too.
6. Help me finish the README's account and permissions checklist, then report
   what passed and anything that still needs my action.
Do the installation and configuration work yourself. Involve me for password
prompts, browser sign-ins, macOS approvals and choices you cannot infer.
```

The agent handles cloning, package installation, config links, shared skills, the WezTerm config copy and verification. Keep Terminal available for administrator password prompts.

If the checkout is already present, start the agent there and ask it to read `AGENTS.md` and run `./scripts/bootstrap.sh`.

The prompt uses `gh` directly for initial authentication because `gh-axi` is not installed yet and does not wrap `auth`. HTTPS cloning avoids needing a new SSH key.

`bootstrap.sh` installs missing Homebrew, runs `packages.sh` then `install.sh`, backs up a differing WezTerm config before copying the repo version, and runs `check.sh`. Rerunning it skips installed programs and configs already in place. Run `./scripts/check.sh` separately for a read-only installation check.

On macOS, the installed apps include Brave, Tailscale, WezTerm, Maccy, VS Code, Docker Desktop and KeepingYouAwake. Google Chrome is also installed for browser automation. A new machine gets the latest versions; exceptions are in [`programs/programs.md`](programs/programs.md).

### 3. Finish sign-ins and permissions with the agent

The agent drives these checks and configuration steps. You complete browser sign-ins, password prompts, macOS approvals and personal choices:

- Open a new WezTerm window and confirm the prompt, completion and `code .` work.
- Finish `gh auth login` and `codex login` if still needed. Start Claude Code once with `claude` and sign in.
- Confirm Git's `user.name` and `user.email`, and configure missing values using your preferred commit identity.
- Open Docker Desktop and finish its first-run setup. Check `docker info` after its engine starts.
- Open Tailscale, sign in and approve its macOS network extension.
- Open Maccy and enable its requested permissions. Open KeepingYouAwake and set launch-at-login preferences if wanted.
- Sign into VS Code Settings Sync and your browser accounts to restore their settings and extensions.
- Provision machine-local secrets and any provider-managed plugins separately. Codex's ignored config and account credentials do not travel through Git.

Installation checks cover commands, apps, config links, shared skills and the WezTerm config. They do not claim that accounts are signed in, permissions are granted or Docker's engine is running.

### Windows and WSL

The new `bootstrap.sh` and `check.sh` cover macOS. On Windows, install WSL with Ubuntu first, clone inside WSL, then run `./scripts/packages.sh` followed by `./scripts/install.sh`. Apply `dotfiles/windows/` on the host and follow [`programs/wezterm.md`](programs/wezterm.md) and [`programs/vscode.md`](programs/vscode.md) for host apps.

### Before moving to the other machine

Commit and push the reviewed changes on the current machine first, including files under `dotfiles/home/.agents/skills/`. A fresh clone only receives committed, pushed files. Never add `dotfiles/home/.codex/config.toml` or account credentials; the config is intentionally ignored.

For changes to the setup scripts, run `python3 -B -m unittest discover -s tests -v` and `shellcheck -x scripts/*.sh scripts/lib/*.sh`. The tests use a temporary home and mocked installers so they do not install software on the current machine.

## Shared skills and provider settings

Custom skills live in `dotfiles/home/.agents/skills/<name>/`. Run `./scripts/install.sh` after adding a skill: it links every shared skill into `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills` and `~/.grok/skills`. The same source serves every configured provider. Add new provider paths to the installer when introducing another provider.

Claude and Grok settings and the shared global instructions already use this repository. Codex settings are adopted from `~/.codex/config.toml` on first install, then symlinked back. That file remains Git-ignored because it contains an OAuth secret; provision it locally on a new machine.

Provider-managed bundled skills, plugin caches and account-synced skills are not portable custom skills. They keep their provider lifecycle and tool dependencies. Credentials, session history and runtime databases remain managed by their applications.
