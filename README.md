# dev-setup

Sergio's config files, tracked in git and symlinked into place — editing a config
*is* editing this repo, so `git commit` is the whole sync workflow.

## Bootstrap on a new WSL/Linux machine

```sh
git clone <this-repo> ~/dev-setup
cd ~/dev-setup
./packages.sh   # installs tmux, nvim
./install.sh    # symlinks tracked files into $HOME
```

Both scripts are idempotent — re-running them is safe and just reports
"already installed" / "already linked".

## What's tracked

| File | Applied by | Notes |
|---|---|---|
| `home/.bashrc` | `install.sh` | symlinked to `~/.bashrc` |
| `home/.profile` | `install.sh` | symlinked to `~/.profile` |
| `home/.config/nvim/init.lua` | `install.sh` | symlinked to `~/.config/nvim/init.lua` |
| `home/.config/nvim/lazy-lock.json` | `install.sh` | symlinked to `~/.config/nvim/lazy-lock.json` |
| `home/.claude/settings.json` | `install.sh` | symlinked to `~/.claude/settings.json` — only this file, never the rest of `~/.claude` (credentials, sessions, history) |
| `windows/.gitconfig` | manual | copy to `%USERPROFILE%\.gitconfig` |
| `windows/.wslconfig` | manual | copy to `%USERPROFILE%\.wslconfig` |
| `windows/.wezterm.lua` | manual | copy to `%USERPROFILE%\.wezterm.lua`; install WezTerm itself via `winget install wez.wezterm` |

The `windows/` files aren't auto-applied because `install.sh` only runs inside
WSL and symlinking into the Windows profile needs admin `mklink` — out of
scope for now.

## What's intentionally excluded

- **`.npmrc`** — contains a live Azure DevOps auth token in plaintext. Never
  put this in git, even in a private repo. Manage it locally instead.
- **`.ssh/`, `.aws/`** — private keys and cloud credentials.
- Everything under `~/.claude` except `settings.json` — credentials, session
  history, cache.
