# agents/

Everything about agents in one directory.

| Path | What's in it |
|---|---|
| `AGENTS.md` | the rule set every agent working *on this repo* follows, reached through the one-line `@../agents/AGENTS.md` import in `.claude/CLAUDE.md` |
| `sub-agents/` | the shelf: curated subagent definitions, one Markdown file per agent, none of them active |

Neither path is scanned by Claude Code.
Only `.claude/agents/` is, which is what makes the shelf a shelf.

## Subagents: keep only the few you use

A subagent is a Markdown file with YAML frontmatter that defines a separate Claude instance with its own system prompt, tool allowlist, model, and context window.
It does its work in isolation and returns only a summary, so the main conversation never sees the intermediate file dumps.

The temptation with collections like [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) (154+ agents) is to install everything.
Don't.
The cost is paid per agent *installed*, not per agent *used*, and there are two parts to it:

1. **Tokens.** Every agent file's `name` and `description` is injected into the main context on every single turn, whether or not the agent is ever called. Only the body is lazy-loaded.
2. **Worse routing, which is the bigger problem.** Claude auto-delegates by matching the request against those descriptions. With a handful of agents the right one is unambiguous. With 154, `backend-developer`, `api-designer`, `graphql-architect`, `microservices-architect` and `fullstack-developer` all plausibly match "add an endpoint". Claude picks one, often not the one you would have picked, and does not announce the choice.

So the rule is: add an agent when there is a recurring task you would otherwise re-explain every time.
Not because it reads well on a README.
Under 10 active is a sane ceiling.
Wanting an eleventh usually means two existing ones should be merged, or one should be deleted.

Collected agents also tend to be verbose and generic, written to impress rather than to work.
Trim one down to the actual stack before treating it as finished.
Watch the `tools:` frontmatter field too: it is an allowlist, and omitting it grants everything, Bash included.

## Why the shelf is a separate directory

Claude Code scans `.claude/agents/` and `~/.claude/agents/` **recursively**, so subfolders inside them are still fully loaded.
Identity comes only from the `name` frontmatter field, never from the path.
That means a subfolder cannot be used as a staging area: `.claude/agents/shelf/foo.md` costs exactly as much context as `.claude/agents/foo.md`.

Hence three locations with genuinely different behaviour:

| Path | Loaded? | Purpose |
|---|---|---|
| `agents/sub-agents/` | no | the shelf: curated, trimmed agents, versioned but costing nothing |
| `dotfiles/home/.claude/agents/` | yes, globally | active agents, symlinked to `~/.claude/agents/` |
| a project's own `.claude/agents/` | yes, in that project | active for one codebase only |

The shelf sits here rather than under `dotfiles/` because `dotfiles/` means "gets deployed to a machine", and the shelf deliberately never is.

`dotfiles/home/.claude/agents/` is intentionally empty apart from `.gitkeep`.
The `.gitkeep` keeps the directory tracked so `install.sh` can still create the symlink, which is what makes activation a one-line copy.

## Activating and deactivating

Globally, for something wanted on every machine and every project:

```sh
cp agents/sub-agents/SimonSinek.md ~/.claude/agents/   # ~/.claude/agents is a symlink into this repo
git add dotfiles/home/.claude/agents/SimonSinek.md
```

For one project only, which is the cheaper default:

```sh
cp ~/dev-setup/agents/sub-agents/SimonSinek.md .claude/agents/
```

Deactivating is `git rm` on the copy under `dotfiles/home/.claude/agents/`; the shelf copy is untouched.
No restart needed either way: Claude Code watches both directories and picks up changes within a few seconds.

Keep `name` values unique across the whole tree.
Two files declaring the same `name` under one `.claude/agents/` directory means only one loads, chosen by filesystem read order with no documented precedence.
`/doctor` reports the collision.

## Adding to the shelf

```sh
BASE=https://raw.githubusercontent.com/VoltAgent/awesome-claude-code-subagents/main/categories
curl -s -o agents/sub-agents/code-reviewer.md $BASE/04-quality-security/code-reviewer.md
```

Then read it, cut it down, and commit.
Nothing is loaded until it is copied into a `.claude/agents/` directory, so the shelf can grow without cost.

The upstream repo also publishes each category as a plugin (`claude plugin marketplace add VoltAgent/awesome-claude-code-subagents`, then `claude plugin install voltagent-qa-sec`).
That route is not used here: plugins land in the untracked `~/.claude/plugins/`, install 16 agents at a time, and would need re-adding by hand on every machine.
Files in this repo sync for free.
`claude plugin details <name>` shows a projected token cost, which is worth a look before installing any plugin.
