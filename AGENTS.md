# Agent instructions for dev-setup

This repo is Sergio's machine setup: the programs to install and the config files that go with them.
Configs are tracked in git and symlinked into `$HOME`, so editing a config *is* editing this repo and `git commit` is the whole sync workflow.
See `README.md` for the full layout.

## Golden rule: after pulling, sync all

"pull and apply latest" is never just `git pull`.
A pull can bring in new configs, new programs, or both, and neither reaches the machine on its own.
After every `git pull`, run **both** sync scripts, in this order:

```sh
./scripts/packages.sh   # install any new programs / binaries
./scripts/install.sh    # symlink any new config files into $HOME
```

Both are idempotent: they skip whatever is already in place, so running them after a no-op pull is harmless.

## Why both scripts, always

They do different jobs, and running only one leaves the machine half-applied:

- `install.sh` **only symlinks config files**. It never installs software.
- `packages.sh` **installs the programs** the configs assume exist (Homebrew on macOS, apt plus GitHub-release binaries on WSL/Linux).

A pull that adds a program ships its config too.
Skip `packages.sh` and the config links fine while the binary is still `command not found`.
Run `packages.sh` first so the programs exist, then `install.sh` to link their configs.

## Gotchas

- Editing a symlinked config edits the repo directly. To sync a change to other machines, commit and push it.
- `.claude/settings.json` is symlinked, and Claude Code rewrites it in place (reordering keys, tweaking `theme`).
  This surfaces as a phantom uncommitted diff after a session. It is noise, safe to discard with `git checkout --` before pulling.
- `packages.sh` may set zsh as the default shell and prompt for a password. Shell and program changes only take effect in a new terminal or after `source ~/.zshrc`.
- WezTerm is not handled by either script. Follow `programs/wezterm.md` to install and configure it by hand on Windows and macOS.
- `dotfiles/windows/` is applied manually on the Windows host, since `install.sh` runs inside WSL and cannot write the Windows profile.
