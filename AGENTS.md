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

Running only one leaves the machine half-applied.
`install.sh` **only symlinks configs** and never installs software; `packages.sh` **only installs programs** (Homebrew on macOS, apt plus GitHub-release binaries on WSL/Linux).
A pull that adds a program ships its config too, so `install.sh` alone links a config whose binary is still `command not found`.
Hence the order: programs first, then their configs.

## Gotchas

- Editing a symlinked config edits the repo directly. To sync a change to other machines, commit and push it.
- This file is the project rule set, and it is the only place project rules go.
  It sits at the repo root so that any agent which auto-discovers `AGENTS.md` finds it with no extra wiring.
  Claude Code reads `CLAUDE.md` and never `AGENTS.md`, so `.claude/CLAUDE.md` is a one-line `@../AGENTS.md` import that points back here.
  An import is used instead of a symlink because git symlinks need Administrator or Developer Mode on a Windows checkout.
  Globally the rule set is shared by symlink instead: `dotfiles/home/AGENTS.md` is linked to `~/AGENTS.md`, `~/.claude/CLAUDE.md` and `~/.grok/AGENTS.md`, which is safe because `install.sh` runs inside WSL.
- `agents/sub-agents/` holding no active agents and `dotfiles/home/.claude/agents/` holding nothing but `.gitkeep` are both deliberate, not oversights to fix.
  Never move agents into a `.claude/agents/` directory to "activate" them: it is scanned recursively, so anything under it costs main-context tokens every turn. [`agents/README.md`](agents/README.md) has the reasoning and the activation steps.
- `dotfiles/home/.claude/settings.json` is symlinked to `~/.claude/settings.json`, and Claude Code rewrites it in place (reordering keys, tweaking `theme`).
  This surfaces as a phantom uncommitted diff after a session. It is noise, safe to discard with `git checkout --` before pulling.
- `dotfiles/home/.grok/config.toml` is symlinked to `~/.grok/config.toml` the same way.
  Grok may also rewrite marketplace flags there; treat pure runtime churn the same as Claude's settings noise.
- `packages.sh` may set zsh as the default shell and prompt for a password. Shell and program changes only take effect in a new terminal or after `source ~/.zshrc`.
- WezTerm is not handled by either script. Follow `programs/wezterm.md` to install and configure it by hand on Windows and macOS.
- `dotfiles/windows/` is applied manually on the Windows host, since `install.sh` runs inside WSL and cannot write the Windows profile.
