# agents/

The subagent shelf: curated definitions in `sub-agents/`, none of them active.
The repo rule set lives at the root, in [`AGENTS.md`](../AGENTS.md).

Claude Code scans `.claude/agents/` **recursively** and takes an agent's identity from its `name` frontmatter, never from its path.
So a subfolder cannot serve as a staging area, and the shelf has to live outside those directories to cost nothing.

| Path | Loaded? | Purpose |
|---|---|---|
| `agents/sub-agents/` | no | the shelf: versioned, costs nothing |
| `dotfiles/home/.claude/agents/` | yes, globally | active everywhere, symlinked to `~/.claude/agents/` (empty apart from `.gitkeep`, which keeps the symlink working) |
| a project's own `.claude/agents/` | yes, in that project | active for one codebase |

## Activating

```sh
cp agents/sub-agents/SimonSinek.md ~/.claude/agents/   # globally: symlink into this repo
git add dotfiles/home/.claude/agents/SimonSinek.md

cp ~/dev-setup/agents/sub-agents/SimonSinek.md .claude/agents/   # one project, the cheaper default
```

Deactivate with `git rm` on the copy under `dotfiles/home/.claude/agents/`, leaving the shelf copy alone.
No restart needed, both directories are watched.

## Rules worth keeping

- Cost is paid per agent *installed*, not used: every `name` and `description` enters the main context each turn, and more agents means worse auto-delegation between similar descriptions. Under 10 active is a sane ceiling.
- Keep `name` unique across the tree. Two files with the same `name` in one directory means only one loads, by filesystem order. `/doctor` reports the collision.
- `tools:` is an allowlist, and omitting it grants everything, Bash included.
- The shelf can grow for free, so be strict only about what gets activated. Trim a collected agent to the actual stack before committing it.
