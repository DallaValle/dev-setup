# Programs

Software the tracked configs assume is present.
`scripts/packages.sh` installs the ones that can be automated, the rest are manual.

| Program | Platform | Install | Config |
|---|---|---|---|
| tmux | WSL/Linux, macOS | `scripts/packages.sh` (apt / Homebrew) | none tracked yet |
| WezTerm | Windows, macOS | follow [`programs/wezterm.md`](wezterm.md) (same setup on both) | `dotfiles/wezterm/.wezterm.lua` |
| Git | all | preinstalled / OS package manager | `dotfiles/windows/.gitconfig` |
| Claude Code | all | see docs.claude.com | `dotfiles/home/.claude/` |
